# frozen_string_literal: true

module Decidim
  module Federa
    class CreateOmniauthFederaRegistration < ::Decidim::CreateOmniauthRegistration

      private

      def create_or_find_user
        generated_password = SecureRandom.hex

        @user = User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if persisted = @user.persisted?
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
          # @user.nickname = form.normalized_nickname if form.invitation_token.present?
          # @user.name = form.name if form.invitation_token.present?
          @user.name = form.name
          @user.nickname = form.nickname
          @user.password = generated_password
          @user.password_confirmation = generated_password
        else
          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = @form.newsletter ? Time.current : nil
          @user.email_on_notification = true
          @user.password = generated_password
          @user.password_confirmation = generated_password
          if form.avatar_url.present?
            url = URI.parse(form.avatar_url)
            filename = File.basename(url.path)
            file = URI.open(url)
            @user.avatar.attach(io: file, filename: filename)
          end
          @user.skip_confirmation! if verified_email
        end

        @user.tos_agreement = "1"
        @user.save! && persisted && !@user.must_log_with_federa? && Decidim::Federa::FederaJob.perform_later(@user)
      end

      def trigger_omniauth_registration
        ActiveSupport::Notifications.publish(
          "decidim.user.omniauth_registration",
          user_id: @user.id,
          identity_id: @identity.id,
          provider: form.provider,
          uid: form.uid,
          email: form.email,
          name: form.name,
          nickname: form.normalized_nickname,
          avatar_url: form.avatar_url,
          raw_data: form.raw_data
        )
        @user.send(:after_confirmation)
      end

    end

  end
end
