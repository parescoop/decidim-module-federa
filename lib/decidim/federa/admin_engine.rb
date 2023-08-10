# frozen_string_literal: true

require "rails"
require "active_support/all"

require "decidim/core"

module Decidim
  module Federa
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Federa::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      initializer "decidim_federa_admin.mount_routes", before: "decidim_admin.mount_routes" do
        Decidim::Admin::Engine.routes.append do
          mount Decidim::Federa::AdminEngine => "/"
        end
      end

      initializer "decidim_federa.view_helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper Decidim::Federa::Admin::ApplicationHelper
        end
      end

      def load_seed
        nil
      end
    end
  end
end
