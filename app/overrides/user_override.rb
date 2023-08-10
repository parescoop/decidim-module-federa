module Decidim
  class User

    def must_log_with_federa?
      identities.map(&:provider).include?(organization.enabled_omniauth_providers.dig(:federa, :tenant_name))
    end

    # per disabilatare il recupera password se in precedenza hai fatto l'accesso con FedERa
    def send_reset_password_instructions
      errors.add(:email, :cant_recover_password_due_federa) unless !self.must_log_with_federa?
      super
    end

    def unauthenticated_message
      must_log_with_federa? ? :invalid_due_federa : :invalid
    end
  end
end