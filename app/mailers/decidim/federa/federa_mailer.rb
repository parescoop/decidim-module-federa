module Decidim
  module Federa
    class FederaMailer < Decidim::ApplicationMailer
      include Decidim::TranslationsHelper
      include Decidim::SanitizeHelper

      helper Decidim::TranslationsHelper

      def send_notification(user)
        with_user(user) do
          @user = user
          @organization = @user.organization

          subject = I18n.t(
            "subject",
            scope: "decidim.federa.federa_mailer"
          )
          mail(to: user.email, subject: subject)
        end
      end

      def send_update_email_notification(user)
        with_user(user) do
          @user = user
          @organization = @user.organization

          subject = I18n.t("subject", scope: "decidim.pua.federa_mailer.send_update_email_notification")
          mail(to: user.email, subject: subject)
        end
      end
    end
  end
end