

# frozen_string_literal: true

# Aggiunge al controller helper per i filtri

require_dependency Decidim::Admin::Engine.root.join('app', 'controllers', 'decidim', 'admin', 'logs_controller').to_s

module Decidim
  module Admin
    class LogsController < Decidim::Admin::ApplicationController
      include Decidim::Admin::Logs::Filterable

      helper_method :logs

      private

      def logs
        @logs ||= Decidim::ActionLog
                  .where(organization: current_organization)
                  .includes(:participatory_space, :user, :resource, :component, :version)
                  .for_admin

        if params[:q]
          if params[:q][:federa_operation] == 'true'
            identity_ids = Decidim::Identity.where(provider: Decidim::Federa.tenants.map(&:name))
            @logs = @logs.where(resource_type: "Decidim::Identity", resource_id: identity_ids)
          end
          if params[:q][:from].present?
            @logs = @logs.where("created_at >= ?", Date.parse(params[:q][:from]).at_beginning_of_day)
          end
          if params[:q][:to].present?
            @logs = @logs.where("created_at <= ?", Date.parse(params[:q][:to]).at_end_of_day)
          end
          @logs = @logs.where(action: params[:q][:action_type]) if params[:q][:action_type].present?
        end


        @logs = @logs.order(created_at: :desc)
                  .page(params[:page])
                  .per(params[:per_page])
      end

      def collection
        logs
      end

    end
  end
end
