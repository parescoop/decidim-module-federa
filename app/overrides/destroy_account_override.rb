

# Aggiunge la destroy delle autorizzazioni

# frozen_string_literal: true

module Decidim
  class DestroyAccount

    def call
      return broadcast(:invalid) unless @form.valid?

      Decidim::User.transaction do
        destroy_user_account!
        destroy_user_authorizations
        destroy_user_identities
        destroy_user_group_memberships
        destroy_follows
        destroy_participatory_space_private_user
        delegate_destroy_to_participatory_spaces
      end

      Rails.logger.info("decidim-module-spid-cie || Distrutto utente #{@user.id}: il record sul DB è ancora presente, viene soltanto 'ripulito' dai dati personali.")

      broadcast(:ok)
    end

    private

    def destroy_user_account!
      @user.invalidate_all_sessions!

      @user.name = ""
      @user.nickname = ""
      @user.email = ""
      @user.delete_reason = @form.delete_reason
      @user.admin = false if @user.admin?
      @user.deleted_at = Time.current
      @user.skip_reconfirmation!
      @user.avatar.purge
      @user.save!
    end

    def destroy_user_authorizations
      Decidim::Authorization.where(user: @user).destroy_all
    end

  end
end
