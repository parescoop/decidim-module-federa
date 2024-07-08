module Decidim
  module Federa
    class OmniauthFederaRegistrationForm < ::Decidim::OmniauthRegistrationForm

      attribute :invitation_token, String
      attribute :newsletter, Boolean

      validates :nickname, presence: true

      def normalized_nickname
        nickname
      end

      def raw_data
        data = super
        data.is_a?(Hash) ? data.to_json : data
      end

    end
  end
end