

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
            [ :federa_operation, :action_type]
          end

          def filters_with_values
            {
              federa_operation: %w(true),
              action_type: %w(registration login logout),
            }
          end


        end
      end
    end
  end
end
