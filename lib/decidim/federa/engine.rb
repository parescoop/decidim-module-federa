require "rails"
require "decidim/core"

module Decidim
  module Federa
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Federa

      routes do
        devise_scope :user do
          match(
            "/users/sign_out",
            to: "sessions#destroy",
            as: "destroy_user_session",
            via: [:delete, :post]
          )

          match(
            "/users/slo_callback",
            to: "sessions#slo_callback",
            as: "slo_callback_user_session",
            via: [:get]
          )
        end
      end

      initializer "decidim_federa.mount_routes", before: :add_routing_paths do
        Decidim::Core::Engine.routes.prepend do
          mount Decidim::Federa::Engine => "/"
        end
      end

      initializer "decidim_federa.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_federa.setup", before: "devise.omniauth" do
        Decidim::Federa.setup!
      end

      initializer "decidim_federa.session.same_site_none", after: "Expire sessions" do
        Rails.application.config.action_dispatch.cookies_same_site_protection = :none
      end

      overrides = "#{Decidim::Federa::Engine.root}/app/overrides"
      config.to_prepare do
        Rails.autoloaders.main.ignore(overrides)
        Dir.glob("#{overrides}/**/*_override.rb").each do |override|
          load override
        end
      end

    end
  end
end
