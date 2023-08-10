module Decidim
  module Federa
    class FederaJob < ApplicationJob
      queue_as :default

      def perform(user)
        return if user&.email.blank?

        FederaMailer.send_notification(user).deliver_now
      end
    end
  end
end
