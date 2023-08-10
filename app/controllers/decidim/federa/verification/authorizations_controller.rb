module Decidim
  module Federa
    module Verification
      class AuthorizationsController < ::Decidim::Verifications::ApplicationController
        skip_before_action :store_current_location

        helper_method :handler, :unauthorized_methods, :authorization_method, :authorization

        # todo: remove unnecessary
        include Decidim::UserProfile
        # include Decidim::Verifications::Renewable
        helper Decidim::DecidimFormHelper
        helper Decidim::CtaButtonHelper
        helper Decidim::AuthorizationFormHelper
        helper Decidim::TranslationsHelper

        layout "layouts/decidim/user_profile", only: [:new]

        def new
          render :new
        end
      end
    end
  end
end