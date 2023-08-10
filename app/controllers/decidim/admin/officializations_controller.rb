

# Aggiunge il modulo che permette di filtrare per SPID e CIE
require_dependency Decidim::Admin::Engine.root.join('app', 'controllers', 'decidim', 'admin', 'officializations_controller').to_s

module Decidim
  module Admin
    class OfficializationsController < Decidim::Admin::ApplicationController
      include Decidim::Admin::Officializations::FilterableOverrides
    end
  end
end
