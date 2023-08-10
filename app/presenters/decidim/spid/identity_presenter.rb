

# frozen_string_literal: true

module Decidim
  module Spid
    class IdentityPresenter < Decidim::Log::ResourcePresenter
      private

      def present_resource_name
        resource && resource.provider && (Decidim::Spid.tenants.map(&:name).include?(resource.provider) ? 'SPID' : 'CIE')
      end

    end
  end
end