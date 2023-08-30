module Decidim
  module Federa
    class UpdateEmailFederaJob < ApplicationJob
      queue_as :default

      def perform(user)
        return if user&.email.blank?

        FederaMailer.send_update_email_notification(user).deliver_now
      end
    end
  end
end
