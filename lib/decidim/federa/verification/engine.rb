# frozen_string_literal: true

module Decidim
  module Federa
    module Verification
      # This is an engine that performs user authorization.
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::Federa::Verification

        paths["db/migrate"] = nil
        paths["lib/tasks"] = nil

        routes do
          resource :authorizations, only: [:new], as: :authorization

          root to: "authorizations#new"
        end

        initializer "decidim_federa.verification_workflow", after: :load_config_initializers do
          Decidim::Federa.tenants.each do |tenant|
            Decidim::Verifications.register_workflow("#{tenant.name}_identity".to_sym) do |workflow|
              workflow.engine = Decidim::Federa::Verification::Engine
              tenant.workflow_configurator.call(workflow)
            end
          end
        end

        def load_seed
          Decidim::Federa.tenants.each do |tenant|
            # Abilita l'autorizzazione per ogni tenant
            org = Decidim::Organization.first
            org.available_authorizations << "#{tenant.name}_identity".to_sym
            org.save!
          end
        end
      end
    end
  end
end