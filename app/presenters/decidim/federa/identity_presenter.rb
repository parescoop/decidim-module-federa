# frozen_string_literal: true

module Decidim
  module Federa
    class IdentityPresenter < Decidim::Log::ResourcePresenter
      private

      def present_resource_name
        resource && resource.provider && 'FedERa'
      end

    end
  end
end