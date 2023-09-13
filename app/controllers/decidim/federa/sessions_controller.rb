module Decidim
  module Federa
    class SessionsController < ::Decidim::Devise::SessionsController

      def destroy
        return super unless session.delete("decidim-federa.signed_in")

        tenant_name = session["decidim-federa.tenant"]
        raise "Unkown FedERa tenant: #{tenant_name}" unless tenant

        i = current_user.identities.find_by(provider: tenant.name) rescue nil
        Decidim::ActionLogger.log(:logout, current_user, i, {}) if i

        sign_out_path = send("user_#{tenant.name}_omniauth_spslo_path")

        redirect_to sign_out_path
      end

      def slo_callback
        set_flash_message! :notice, :signed_out
        current_user.invalidate_all_sessions!
        return redirect_to(decidim.new_user_session_path) if current_organization.force_users_to_authenticate_before_access_organization

        redirect_to params[:path] || decidim.root_path
      end

      def tenant
        @tenant ||= begin
                      name = session.delete("decidim-federa.tenant")
                      raise "Invalid FedERa tenant" unless name

                      tenant = Decidim::Federa.tenants.find { |t| t.name == name }
                      raise "Unkown FedERa tenant: #{name}" unless tenant

                      tenant
                    end
      end

    end
  end
end
