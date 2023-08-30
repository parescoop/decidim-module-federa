# frozen_string_literal: true

module Decidim
  module Federa
    class OmniauthCallbacksController < ::Decidim::Devise::OmniauthRegistrationsController
      helper Decidim::Federa::Engine.routes.url_helpers
      helper_method :omniauth_registrations_path

      skip_before_action :verify_authenticity_token, only: [:federa, :failure]
      skip_after_action :verify_same_origin_request, only: [:federa, :failure]

      def federa
        session["decidim-federa.signed_in"] = true
        session["decidim-federa.tenant"] = tenant.name

        authenticator.validate!

        if user_signed_in?
          authenticator.identify_user!(current_user)

          # Aggiunge l'autorizzazione per l'utente
          return fail_authorize unless authorize_user(current_user)

          # Aggiorna le informazioni dell'utente
          authenticator.update_user!(current_user, true)

          # to force remain logged in
          u = current_user
          sign_out(current_user)
          sign_in(u) if u.reload.confirmed?
          if !isnt_cie_or_cns? && !u.confirmed?
            flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
          else
            flash[:notice] = t("authorizations.create.success", scope: "decidim.federa.verification")
          end

          Decidim::Federa::FederaJob.perform_later(current_user)
          return redirect_to(stored_location_for(resource || :user) || decidim.root_path)
        end

        # Normale richiesta di autorizzazione, procede con la logica di Decidim
        send(:create)

      rescue Decidim::Federa::Authentication::ValidationError => e
        fail_authorize(e.validation_key)
      rescue Decidim::Federa::Authentication::IdentityBoundToOtherUserError
        fail_authorize(:identity_bound_to_other_user)
      end

      def create
        form_params = user_params_from_oauth_hash || params.require(:user).permit!
        form_params.merge!(params.require(:user).permit!) if params.dig(:user).present?
        origin = Base64.strict_decode64(params['RelayState']) rescue ''

        invitation_token = invitation_token(origin)
        verified_e = verified_email

        # nel caso la form di integrazione dati viene presentata
        invited_user = nil
        if invitation_token.present?
          invited_user = resource_class.find_by_invitation_token(invitation_token, true)
          invited_user.nickname = nil # Forzo nickname a nil per invalidare il valore normalizzato di Decidim di default
          form_params[:name] = params.dig(:user, :name).present? ? params.dig(:user, :name) : invited_user.name
          @form = form(OmniauthFederaRegistrationForm).from_params(invited_user.attributes.merge(form_params))
          @form.invitation_token = invitation_token
          @form.email ||= invited_user.email
          verified_e = invited_user.email
        else
          if current_provider && isnt_cie_or_cns? && (u = current_organization.users.find_by(email: verified_e))
            form_params[:name] = u.name
            form_params[:nickname] = u.nickname
          else
            form_params[:name] = params.dig(:user, :name) if params.dig(:user, :name).present? && isnt_cie_or_cns?
            form_params[:nickname] = params.dig(:user, :nickname) if params.dig(:user, :nickname).present? && isnt_cie_or_cns?
          end
          @form = form(OmniauthFederaRegistrationForm).from_params(form_params)
          @form.email ||= verified_e
          verified_e ||= form_params.dig(:email)
        end

        # Controllo che non esisti un'altro account con la stessa email utilizzata con FEDERA
        # in quanto a fine processo all'utente viene aggiornata l'email e il tutto protrebbe essere invalido
        if invited_user.present? && form_params.dig(:raw_data, :info, :email).present? && invited_user.email != form_params.dig(:raw_data, :info, :email) &&
          current_organization.users.where(email: form_params.dig(:raw_data, :info, :email)).where.not(id: invited_user.id).present?
          set_flash_message :alert, :failure, kind: "FedERa", reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        existing_identity = Identity.find_by(
          user: current_organization.users,
          provider: @form.provider,
          uid: @form.uid
        )

        CreateOmniauthFederaRegistration.call(@form, verified_e) do
          on(:ok) do |user|
            # Se l'identità FEDERA è già utilizzata da un altro account
            if invited_user.present? && invited_user.email != user.email
              set_flash_message :alert, :failure, kind: "FedERa", reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
              return redirect_to after_omniauth_failure_path_for(resource_name)
            end

            # match l'utente dell'invitation token passato come relay_state in FEDERA Strategy,
            # associo l'identity FEDERA all'utente creato nell'invitation e aggiorno l'email dell'utente con quella dello FEDERA.
            if invitation_token.present? && invited_user.present? && invited_user.email == user.email
              # per accettare resource_class.accept_invitation!(devise_parameter_sanitizer.sanitize(:accept_invitation).merge(invitation_token: invitation_token))
              user = resource_class.find_by_invitation_token(invitation_token, true)
              # nuovo utente senza password, fallirebbero le validazioni
              token = ::Devise.friendly_token
              user.password = token
              user.password_confirmation = token
              user.save(validate: false)
              user.accept_invitation!
            end

            if user.active_for_authentication?
              if existing_identity
                Decidim::ActionLogger.log(:login, user, existing_identity, {})
              else
                i = user.identities.find_by(uid: @form.uid) rescue nil
                Decidim::ActionLogger.log(:registration, user, i, {})
              end
              sign_in_and_redirect user, verified_email: verified_e, event: :authentication
              set_flash_message :notice, :success, kind: "FedERa"
            else
              expire_data_after_sign_in!
              user.resend_confirmation_instructions unless user.confirmed?
              redirect_to decidim.root_path
              flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
            end
          end

          on(:invalid) do
            set_flash_message :notice, :success, kind: "FedERa"
            render :new
          end

          on(:error) do |user|
            set_flash_message :alert, :failure, kind: "FedERa", reason: user.errors.full_messages.try(:first)

            render :new
          end
        end
      end

      def failure
        strategy = failed_strategy
        saml_response = strategy.response_object if strategy
        return super unless saml_response

        validations = [ :success_status, :session_expiration ]
        validations.each do |key|
          next if saml_response.send("validate_#{key}")

          flash[:alert] = failure_message || t(".#{key}")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        set_flash_message! :alert, :failure, kind: "FedERa", reason: failure_message
        redirect_to after_omniauth_failure_path_for(resource_name)
      end

      def sign_in_and_redirect(resource_or_scope, *args)
        if resource_or_scope.is_a?(::Decidim::User)
          return fail_authorize unless authorize_user(resource_or_scope)

          authenticator.update_user!(resource_or_scope)
        end

        super
      end

      def first_login_and_not_authorized?(_user)
        false
      end

      protected

      def failure_message
        error = request.respond_to?(:get_header) ? request.get_header("omniauth.error") : request.env["omniauth.error"]
        I18n.t(error) rescue nil
      end

      private

      def authorize_user(user)
        authenticator.authorize_user!(user)
      rescue Decidim::Federa::Authentication::AuthorizationBoundToOtherUserError
        nil
      end

      def fail_authorize(failure_message_key = :already_authorized)
        flash[:alert] = t("failure.#{failure_message_key}", scope: "decidim.federa.omniauth_callbacks")
        redirect_to stored_location_for(resource || :user) || decidim.root_path
      end

      def omniauth_registrations_path(resource)
        decidim_federa.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:federa, :tenant_name)}_omniauth_create_url")
      end

      def user_params_from_oauth_hash
        authenticator.user_params_from_oauth_hash
      end

      def authenticator
        @authenticator ||= tenant.authenticator_for(
          current_organization,
          oauth_hash
        )
      end

      def tenant
        @tenant ||= begin
                      matches = request.path.match(%r{^/users/auth/([^/]+)/.+})
                      raise "Invalid FedERa tenant" unless matches

                      name = matches[1]
                      tenant = Decidim::Federa.tenants.find { |t| t.name == name }
                      raise "Unkown FedERa tenant: #{name}" unless tenant

                      tenant
                    end
      end

      def session_prefix
        tenant.name + '_federa_'
      end

      def invitation_token(url)
        begin
          CGI.parse(URI.parse(url).query).dig('invitation_token').first
        rescue
          nil
        end
      end

      def verified_email
        authenticator.verified_email
      end

      def oauth_hash
        raw_hash = request.env["omniauth.auth"] || JSON.parse(params.dig(:user, :raw_data))
        return {} unless raw_hash
        raw_hash.try(:[], 'extra').try(:delete, 'response_object')

        raw_hash.deep_symbolize_keys
      end

      def isnt_cie_or_cns?
        current_provider && !["smartcard"].include?(current_provider.try(&:downcase))
      end

      def current_provider
        @current_provider ||= current_provider = oauth_hash.dig(:extra, :raw_info, :authenticationMethod)
      end
    end
  end
end
