module Decidim
  module Admin
    module Officializations
      module FilterableOverrides

        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            c = collection
            federa_filter = to_boolean(ransack_params.delete(:federa_presence))
            unless federa_filter.nil?
              c = federa_filter ? c.where(id: federa_ids) : c.where.not(id: federa_ids)
            end

            c.distinct
          end

          def search_field_predicate
            :name_or_nickname_or_email_cont
          end

          def filters
            [:officialized_at_null, :federa_presence]
          end

          def to_boolean(str)
            return if str.nil?
            str == 'true'
          end

          def federa_ids
            Decidim::Identity.where(provider: Decidim::Federa.tenants.map(&:name)).pluck(:decidim_user_id)
          end

        end
      end
    end
  end
end