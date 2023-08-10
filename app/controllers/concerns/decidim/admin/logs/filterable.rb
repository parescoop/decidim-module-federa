

# frozen_string_literal: true

# Definizione filtri
require "active_support/concern"

module Decidim
  module Admin
    module Logs
      module Filterable
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            collection
          end

          def filters
            [ :spid_operation, :cie_operation, :action_type]
          end

          def filters_with_values
            {
              spid_operation: %w(true),
              cie_operation: %w(true),
              action_type: %w(registration login logout),
            }
          end


        end
      end
    end
  end
end
