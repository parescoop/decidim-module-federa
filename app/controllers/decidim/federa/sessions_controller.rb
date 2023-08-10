module Decidim
  module Federa
    class SessionsController < ::Decidim::Devise::SessionsController

      def destroy
        if session.delete("decidim-federa.signed_in")
          i = current_user.identities.find_by(uid: session["#{session_prefix}uid"]) rescue nil
          Decidim::ActionLogger.log(:logout, current_user, i, {}) if i
          redirect_to decidim_federa.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:federa, :tenant_name)}_omniauth_spslo_url")
        else
          super
        end
      end

      def slo_callback
        set_flash_message! :notice, :signed_out if params[:success] == "true"
        current_user.invalidate_all_sessions!
        return redirect_to(decidim.new_user_session_path) if current_organization.force_users_to_authenticate_before_access_organization

        redirect_to params[:path] || decidim.root_path
      end

      def tenant
        @tenant ||= begin
                      name = session["tenant-federa-name"]
                      raise "Invalid FedERa tenant" unless name

                      tenant = Decidim::Federa.tenants.find { |t| t.name == name }
                      raise "Unkown FedERa tenant: #{name}" unless tenant

                      tenant
                    end
      end

      def session_prefix
        tenant.name + '_federa_'
      end
    end
  end
end
