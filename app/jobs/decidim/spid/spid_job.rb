

# frozen_string_literal: true

# SPID notification job to send email
module Decidim
  module Spid
    class SpidJob < ApplicationJob
      queue_as :default

      def perform(user)
        return if user&.email.blank?

        SpidMailer.send_notification(user).deliver_now
      end
    end
  end
end
