# frozen_string_literal: true

module Decidim
  module Federa
    module Admin
      module ApplicationHelper

        def federa_icon
          content_tag :span, class: 'federa-badge' do
            image_pack_tag 'media/images/federa-logo.svg', alt: "FedERa Icon"
          end
        end
      end
    end
  end
end
