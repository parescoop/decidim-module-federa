# frozen_string_literal: true

module Decidim
  module Federa
    module Authentication
      class Authenticator
        include ActiveModel::Validations

        def initialize(tenant, organization, oauth_hash)
          @tenant = tenant
          @organization = organization
          @oauth_hash = oauth_hash
          @new_user = false
        end

        def verified_email
          @verified_email ||= begin
                                oauth_data[:info][:email].try(:downcase)
                              rescue
                                nil
                              end
        end

        def user_params_from_oauth_hash
          return nil if oauth_data.empty?
          return nil if user_identifier.blank?
          existing_user = Decidim::User.find_by(organization: organization, email: verified_email)
          existing_user = nil if existing_user && !existing_user.must_log_with_federa?
          {
            provider: oauth_data[:provider],
            uid: user_identifier,
            name: existing_user.try(:name) || "#{oauth_data.dig(:info, :first_name)} #{oauth_data.dig(:info, :last_name)}",
            # nickname: oauth_data[:info][:nickname] || oauth_data[:info][:name],
            oauth_signature: user_signature,
            avatar_url: oauth_data[:info][:image],
            raw_data: oauth_hash
          }.merge(
            existing_user ? { nickname: existing_user.try(:nickname) } : {}
          )
        end

        def validate!
          raise ValidationError, "No SAML data provided" unless saml_attributes

          actual_attributes = saml_attributes
          # actual_attributes = saml_attributes.attributes
          # actual_attributes.delete("fingerprint")
          raise ValidationError, "No SAML data provided" if actual_attributes.blank?

          data_blank = actual_attributes.all? { |_k, val| val.blank? }
          raise ValidationError, "Invalid SAML data" if data_blank
          raise ValidationError, "Invalid person dentifier" if person_identifier_digest.blank?

          # Controlla se esiste un identity per un utente di esistente. Se l'identity
          # non è trovata, l'utente è loggato come nuovo utente.
          id = ::Decidim::Identity.find_by(
            organization: organization,
            provider: oauth_data[:provider],
            uid: user_identifier
          )
          @new_user = id ? id.user.blank? : true

          true
        end

        def identify_user!(user)
          identity = user.identities.find_by(
            organization: organization,
            provider: oauth_data[:provider],
            uid: user_identifier
          )
          Decidim::ActionLogger.log(:login, user, identity, {}) if identity
          return identity if identity

          # Check that the identity is not already bound to another user.
          id = ::Decidim::Identity.find_by(
            organization: organization,
            provider: oauth_data[:provider],
            uid: user_identifier
          )

          raise IdentityBoundToOtherUserError if id

          i = user.identities.create!(
            organization: organization,
            provider: oauth_data[:provider],
            uid: user_identifier
          )

          Decidim::ActionLogger.log(:registration, user, i, {})

          i
        end

        def authorize_user!(user)
          authorization = ::Decidim::Authorization.find_by(
            name: "#{tenant.name}_identity",
            unique_id: user_signature
          )
          if authorization
            raise AuthorizationBoundToOtherUserError if authorization.user != user
          else
            authorization = ::Decidim::Authorization.find_or_initialize_by(
              name: "#{tenant.name}_identity",
              user: user
            )
          end

          authorization.attributes = {
            unique_id: user_signature,
            metadata: authorization_metadata
          }
          authorization.save!

          # Dipendenza decidim-minors_auth
          if user && user.respond_to?(:fiscal_code) && defined?(Decidim::MinorsAuth)
            user.update(fiscal_code: user_identifier.try(:upcase))
          end

          tenant.run_authorization_handlers(user: user, document_number: user_identifier, document_type: :FEDERA)

          authorization.grant! unless authorization.granted?

          authorization
        end

        def update_user!(user, force= false)
          user_changed = false
          generated_password = SecureRandom.hex
          user.password = generated_password
          user.password_confirmation = generated_password
          user.save

          if (verified_email.present? && (user.email != verified_email)) || force
            user_changed = true
            if is_spid?
              user.skip_reconfirmation!
            else
              user.confirmed_at = nil if verified_email.present? && (user.email != verified_email)
              # user.resend_confirmation_instructions unless user.confirmed?
            end
            user.email = verified_email if verified_email.present?
          end
          # user.newsletter_notifications_at = Time.zone.now if user_newsletter_subscription?(user)
          notification_email = user.email_changed?
          if user.valid?
            if user_changed
              if user.save! && is_spid? && notification_email
                Decidim::Federa::UpdateEmailFederaJob.perform_later(user)
              end
            end
          else
            if (user.errors.details.all?{ |k,v| k == :email && v.flatten.map{ |k| k[:error] }.all?(:taken) } rescue false)
              Rails.logger.info("decidim-module-federa || L'utente #{user.id} ha un'altro account decidim con la stessa email dello PUA richiesto. Non aggiorno l'email.")
              user.reload
            end
          end
        end

        protected

        attr_reader :organization, :tenant, :oauth_hash

        def oauth_data
          @oauth_data ||= oauth_hash.slice(:provider, :uid, :info)
        end

        def saml_attributes
          @saml_attributes ||= oauth_hash.dig(:extra, :raw_info)
        end

        def user_identifier
          @user_identifier ||= oauth_data[:uid]
        end

        def user_signature
          @user_signature ||= ::Decidim::OmniauthRegistrationForm.create_signature(
            oauth_data[:provider],
            user_identifier
          )
        end

        def metadata_collector
          @metadata_collector ||= tenant.metadata_collector_for(saml_attributes)
        end

        def authorization_metadata
          metadata_collector.metadata
        end

        def person_identifier_digest
          return if user_identifier.blank?

          @person_identifier_digest ||= Digest::MD5.hexdigest(
            "#{tenant.name.upcase}:#{user_identifier}:#{Rails.application.secrets.secret_key_base}"
          )
        end

        def is_spid?
          !("smartcard" == oauth_hash.dig(:extra, :raw_info, :authenticationMethod).try(:first).try(:downcase))
        end
      end
    end
  end
end
