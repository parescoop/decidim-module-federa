# frozen_string_literal: true

module Decidim
  module Federa
    class Settings < OneLogin::RubySaml::Settings
      attr_accessor :sp_metadata, :idp_sso_service_url_runtime_params
    end
  end
end