# frozen_string_literal: true

module Decidim
  module Federa
    class Settings < OneLogin::RubySaml::Settings
      attr_accessor :sp_metadata, :idp_sso_service_url_runtime_params

      def initialize(overrides = nil, keep_security_attributes = nil)
        super
        @authn_context = case overrides.delete(:spid_level)
                         when 1 then "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
                         when 2 then "urn:oasis:names:tc:SAML:2.0:ac:classes:SecureRemotePassword"
                         when 3 then "urn:oasis:names:tc:SAML:2.0:ac:classes:Smartcard"
                         end
      end
    end
  end
end