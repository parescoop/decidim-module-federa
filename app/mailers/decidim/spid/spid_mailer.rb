

# frozen_string_literal: true

# Invia notifica email per informare l'utente che l'account è stato migrato
module Decidim
  module Spid
    class SpidMailer < Decidim::ApplicationMailer
      include Decidim::TranslationsHelper
      include Decidim::SanitizeHelper

      helper Decidim::TranslationsHelper

      def send_notification(user)
        with_user(user) do
          @user = user
          @organization = @user.organization

          subject = I18n.t(
            "subject",
            scope: "decidim.spid.spid_mailer"
          )
          mail(to: user.email, subject: subject)
        end
      end
    end
  end
end