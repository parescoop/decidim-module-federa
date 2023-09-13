# frozen_string_literal: true

require 'decidim/federa/token_verifier'

module Decidim
  module Federa
    class Tenant
      include ActiveSupport::Configurable

      # Il nome che identificata il singolo Tenant. Default: federa
      config_accessor :name, instance_writer: false do
        "federa"
      end

      # Provider metadata file
      config_accessor :idp_metadata_file
      # Provider metadata url. Default: FedERa in secrets.yml
      config_accessor :idp_metadata_url

      # Definisce l'entity ID del service provider
      config_accessor :sp_entity_id, instance_reader: false do
        ''
      end

      # Certificato in stringa
      config_accessor :certificate, instance_reader: true

      # Percorso relativo alla root dell'app del certificato
      config_accessor :certificate_file do
        '.keys/certificate.pem'
      end

      # Chiave privata in stringa
      config_accessor :private_key, instance_reader: false

      # Percorso relativo alla root dell'app della chiave privata
      config_accessor :private_key_file do
        '.keys/private_key.pem'
      end

      # Nuovo certificato in stringa
      config_accessor :new_certificate, instance_reader: true

      # Percorso relativo alla root dell'app del nuovo certificato
      config_accessor :new_certificate_file do
        nil
      end

      # Le chiavi che verranno salvate nell'autorizzazione (record Decidim::Authorization)
      config_accessor :metadata_attributes do
        {}
      end

      # Extra metadata da include nel metadata. Esempio:
      #
      # Decidim::Federa.configure do |config|
      #   # ...
      #   config.sp_metadata = [
      #     {
      #       name: "Organization",
      #       children: [
      #         {
      #           name: "OrganizationName",
      #           attributes: { "xml:lang" => "en-US" },
      #           content: "Acme"
      #         }
      #       ]
      #     }
      #   ]
      # end
      config_accessor :sp_metadata do
        []
      end

      # Extra configurazioni per la strategy omniauth
      config_accessor :extra do
        {}
      end

      # Per specificare gli attributi
      config_accessor :fields do
        []
      end

      # Permette di customizzare il workflow di autorizzazione.
      config_accessor :workflow_configurator do
        lambda do |workflow|
          # Di default, la scadenza è impostata a 0 minuti e quindi non scadrà
          workflow.expires_in = 0.minutes
          workflow.renewable = false
        end
      end

      # Permette di customizzare parte del flusso di autenticazione (come
      # le validazioni) prima che l'utente venga autenticato.
      config_accessor :authenticator_class do
        Decidim::Federa::Authentication::Authenticator
      end

      # Il livello SPID richiesto dal tenant
      config_accessor :spid_level do
        2
      end

      # Permette di customizzare parte del i metadata collezionati dagli
      # attributi SAML.
      config_accessor :metadata_collector_class do
        Decidim::Federa::Verification::MetadataCollector
      end

      def initialize
        yield self
      end

      def name=(name)
        raise(InvalidTenantName, "Il nome del tenant FEDERA può contenere solo lettere o underscore.") unless name.match?(/^[a-z_]+$/)
        config.name = name
      end

      def authenticator_for(organization, oauth_hash)
        authenticator_class.new(self, organization, oauth_hash)
      end

      def metadata_collector_for(saml_attributes)
        metadata_collector_class.new(self, saml_attributes)
      end

      def sp_entity_id
        return config.sp_entity_id if config.sp_entity_id

        "#{application_host}/users/auth/#{config.name}/metadata"
      end

      def certificate
        return File.read(certificate_file) if certificate_file

        config.certificate
      end

      def new_certificate
        return File.read(new_certificate_file) if new_certificate_file && File.exists?(Rails.root.join(new_certificate_file))

        config.new_certificate
      end

      def private_key
        return File.read(private_key_file) if private_key_file

        config.private_key
      end

      def omniauth_settings
        {
          name: name,
          strategy_class: OmniAuth::Strategies::FederaSaml,
          idp_metadata_file: idp_metadata_file,
          idp_metadata_url: idp_metadata_url,
          sp_entity_id: sp_entity_id,
          sp_name_qualifier: sp_entity_id,
          sp_metadata: sp_metadata,
          certificate: certificate,
          private_key: private_key,
          new_certificate: new_certificate,
          assertion_consumer_service_url: "#{sp_entity_id}/users/auth/#{config.name}/callback",
          request_attributes: fields,
          single_logout_service_url: "#{sp_entity_id}/users/auth/#{config.name}/slo",
          spid_level: spid_level
        }.merge(extra)
      end

      def setup!
        setup_routes!

        # Configure the SAML OmniAuth strategy for Devise
        ::Devise.setup do |config|
          config.omniauth(name.to_sym, omniauth_settings)
        end

        # Customized version of Devise's OmniAuth failure app in order to handle
        # the failures properly. Without this, the failure requests would end
        # up in an ActionController::InvalidAuthenticityToken exception.
        devise_failure_app = OmniAuth.config.on_failure
        # OmniAuth.config.before_callback_phase do |env|
        #   env['omniauth.origin'] = '/users/show'
        # end
        OmniAuth.config.on_failure = proc do |env|
          if env["PATH_INFO"] && env["PATH_INFO"].match?(%r{^/users/auth/#{config.name}($|/.+)})
            env["devise.mapping"] = ::Devise.mappings[:user]
            Decidim::Federa::OmniauthCallbacksController.action(
              :failure
            ).call(env)
          else
            # Call the default for others.
            devise_failure_app.call(env)
          end
        end
      end

      def setup_routes!
        config = self.config
        Decidim::Federa::Engine.routes do
          devise_scope :user do
            # Mappatura delle route
            match(
              "/users/auth/#{config.name}",
              to: "omniauth_callbacks#passthru",
              as: "user_#{config.name}_omniauth_authorize",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/callback",
              to: "omniauth_callbacks#federa",
              as: "user_#{config.name}_omniauth_callback",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/create",
              to: "omniauth_callbacks#create",
              as: "user_#{config.name}_omniauth_create",
              via: [:post, :put, :patch]
            )

            match(
              "/users/auth/#{config.name}/slo",
              to: "sessions#slo",
              as: "user_#{config.name}_omniauth_slo",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/spslo",
              to: "sessions#spslo",
              as: "user_#{config.name}_omniauth_spslo",
              via: [:get, :post]
            )
          end
        end
      end

      def auto_email_for(organization, identifier_digest)
        domain = auto_email_domain || organization.host
        "#{name}-#{identifier_digest}@#{domain}"
      end

      def auto_email_matches?(email)
        return false unless auto_email_domain

        email =~ /^#{name}-[a-z0-9]{32}@#{auto_email_domain}$/
      end

      # Usato per determinare il default service provider entity ID in caso non specificato in sp_entity_id.
      def application_host
        url_options = application_url_options

        host = url_options[:host]
        port = url_options[:port]
        protocol = url_options[:protocol]
        protocol = [80, 3000].include?(port.to_i) ? "http" : "https" if protocol.blank?
        if host.blank?
          host = "localhost"
          port ||= 3000
        end

        return "#{protocol}://#{host}:#{port}" if port && [80, 443].exclude?(port.to_i)

        "#{protocol}://#{host}"
      end

      def application_url_options
        conf = Rails.application.config
        url_options = conf.action_controller.default_url_options
        url_options = conf.action_mailer.default_url_options if !url_options || !url_options[:host]
        url_options || {}
      end
    end
  end
end
