# frozen_string_literal: true

require "omniauth-saml"
require "decidim/federa/settings"
require "decidim/federa/metadata"

module OmniAuth
  module Strategies
    class FederaSaml < SAML
      include OmniAuth::Strategy

      # The IdP metadata file.
      option :idp_metadata_file, nil

      # The IdP aadata URL.
      option :idp_metadata_url, nil

      option :request_attributes, []

      option :uid_attribute, Rails.env.development? ? :fiscalNumber : :CodiceFiscale

      # If you want to pass extra security configurations, use this option.
      option :security, {}

      option :attribute_statements, {
        name: ["name", "nome"],
        email: ["email", "mail", "emailAddressPersonale"],
        first_name: ["first_name", "firstname", "firstName", "nome", "name"],
        last_name: ["last_name", "lastname", "lastName", "cognome", "familyName"]
      }

      option(:sp_metadata, [])

      uid do
        if options.uid_attribute
          ret = find_attribute_by([options.uid_attribute])
          if ret.nil?
            raise OneLogin::RubySaml::ValidationError.new("SAML response missing '#{options.uid_attribute}' attribute")
          end
          ret
        else
          @name_id
        end
      end

      info do
        found_attributes = options.attribute_statements.map do |key, values|
          attribute = find_attribute_by(values)
          [key, attribute]
        end
        Hash[found_attributes]
      end

      extra { { raw_info: @attributes.attributes } }

      # def self.extra_stack(context)
      #   compile_stack([], :extra, context)
      # end


      def initialize(app, *args, &block)
        super

        # Add the request attributes to the options.
        options[:sp_name_qualifier] = options[:sp_entity_id] if options[:sp_name_qualifier].nil?

        # Remove the nil options from the origianl options array that will be
        # defined by the FedERa options
        [
          :idp_name_qualifier,
          :name_identifier_format,
          :security
        ].each do |key|
          options.delete(key) if options[key].nil?
        end

        # Add the FEDERA options to the local options, most of which are fetched
        # from the metadata. The options array is the one that gets priority in
        # case it overrides some of the metadata or locally defined option
        # values.
        @options = OmniAuth::Strategy::Options.new(
          federa_options.merge(options)
        )
      end

      def request_phase
        authn_request = OneLogin::RubySaml::Authrequest.new

        with_settings do |settings|
          redirect_to(authn_request.create(settings, additional_params_for_authn_request.merge('RelayState' => Base64.strict_encode64(session['omniauth.origin'] || '/'))))
        end
      end

      def redirect_to(uri)
        pp = CGI.parse(URI.parse(uri).query)
        if pp["Signature"].present?
          r = Rack::Response.new
          if options[:iframe]
            r.write("<script type='text/javascript' charset='utf-8'>top.location.href = '#{uri}';</script>")
          else
            r.write("Redirecting to #{uri}...")
            r.redirect(uri)
          end
        else
          r = Rack::Response.new"
            <html><body onload='javascript:document.forms[0].submit()'>
              <form method='post' action='#{uri.split("?").first}'>
                <input type='hidden' name='SAMLRequest' value='#{Base64.encode64(OneLogin::RubySaml::SamlMessage.new.send(:decode_raw_saml, pp["SAMLRequest"].first))}'>
                <input type='hidden' name='RelayState' value='#{pp["RelayState"].first}'>
                <input type='submit' value='Invia'/>
              </form>
          </body></html>",
                                200,
                                { 'Content-Type' => 'text/html' }

        end

        r.finish
      end

      # This method can be used externally to fetch information about the
      # response, e.g. in case of failures.
      def response_object
        return nil unless request.params["SAMLResponse"]

        with_settings do |settings|
          response = OneLogin::RubySaml::Response.new(
            request.params["SAMLResponse"],
            options_for_response_object.merge(settings: settings)
          )
          response.attributes["fingerprint"] = settings.idp_cert_fingerprint
          response
        end
      end

      private

      def federa_metadata_options
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new

        if options.idp_metadata_file
          return idp_metadata_parser.parse_to_hash(
            File.read(options.idp_metadata_file)
          )
        end

        begin
          idp_metadata_parser.parse_remote_to_hash(
            options.idp_metadata_url,
            !Rails.env.development?
          )
        rescue ::URI::InvalidURIError
          # Allow the OmniAuth strategy to be configured with empty settings
          # in order to provide the metadata URL even when the authentication
          # endpoint is not configured.
          {}
        end
      end

      def federa_options
        # Returns OneLogin::RubySaml::Settings prepopulated with idp metadata
        settings = federa_metadata_options

        if settings[:idp_slo_response_service_url].nil? && settings[:idp_slo_target_url].nil?
          # Mitigation after ruby-saml update to 1.12.x. This gem has been
          # originally developed relying on the `:idp_slo_target_url` settings
          # which was removed from the newer versions. The SLO requests won't
          # work unless `:idp_slo_response_service_url` is defined in the
          # metadata through the `ResponseLocation` attribute in the
          # `<SingleLogoutService />` node.
          settings[:idp_slo_target_url] ||= settings[:idp_slo_service_url]
        end

        # Define the security settings as there are some defaults that need to be
        # modified
        security_defaults = OneLogin::RubySaml::Settings::DEFAULTS[:security]
        settings[:security] = security_defaults.merge(
          authn_requests_signed: options.certificate.present?,
          want_assertions_signed: true,
          digest_method: XMLSecurity::Document::SHA256,
          signature_method: XMLSecurity::Document::RSA_SHA256
        )
        if options.certificate && options.private_key
          settings[:security][:logout_requests_signed] = true
          settings[:security][:logout_responses_signed] = true
        end

        if options.new_certificate
          settings[:certificate_new] = options.new_certificate
        end

        settings[:security].merge!(options.security)

        # Add some extra information that is necessary for correctly formatted
        # logout requests.
        settings[:idp_name_qualifier] = settings[:idp_entity_id]

        if options.name_identifier_format.present?
          # If the name identifier format has been configured, use that instead
          # of the IdP metadata value. Otherwise the first format available in
          # the IdP metadata would be used.
          settings[:name_identifier_format] = options.name_identifier_format
        elsif settings[:name_identifier_format].blank?
          # If the name identifier format is not defined in the IdP metadata,
          # add the persistent format to the SP metadata.
          settings[:name_identifier_format] = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
        end

        settings
      end

      def with_settings
        options[:assertion_consumer_service_url] ||= callback_url
        yield Decidim::Federa::Settings.new(options)
      end

      # Customize the metadata class in order to add custom nodes to the
      # metadata.
      def other_phase_for_metadata
        with_settings do |settings|
          response = Decidim::Federa::Metadata.new

          add_request_attributes_to(settings) if options.request_attributes.length.positive?

          Rack::Response.new(
            response.generate(settings),
            200,
            "Content-Type" => "application/xml"
          ).finish
        end
      end

      # End the local user session BEFORE sending the logout request to the
      # identity provider.
      def other_phase_for_spslo
        return super unless options.idp_slo_service_url

        with_settings do |settings|
          # Some session variables are needed when generating the logout request
          request = generate_logout_request(settings)
          # Destroy the local user session
          options[:idp_slo_session_destroy].call @env, session
          # Send the logout request to the identity provider
          redirect(request)
        end
      end

      # Overridden to disable passing the relay state with a request parameter
      # which is possible in the default implementation.
      def slo_relay_state
        state = super

        # Ensure that we are only using the relay states to redirect the user
        # within the current website. This forces the relay state to always
        # start with a single forward slash character (/).
        return "/" unless state
        return "/" unless state.match?(%r{^/[^/].*})

        state
      end

    end
  end
end