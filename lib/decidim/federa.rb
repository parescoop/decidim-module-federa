# frozen_string_literal: true

require 'deface'
require 'ruby-saml'
require "omniauth/strategies/federa_saml"

require_relative "federa/version"
require_relative "federa/engine"
require_relative "federa/admin"
require_relative "federa/admin_engine"
require_relative "federa/authentication"
require_relative "federa/verification"

module Decidim
  module Federa
    autoload :Tenant, "decidim/federa/tenant"

    class << self
      def tenants
        @tenants ||= []
      end

      def test!
        @test = true
      end

      def configure(&block)
        tenant = Decidim::Federa::Tenant.new(&block)
        tenants.each do |existing|
          if tenant.name == existing.name
            raise(
              TenantSameName,
              "Definisci il nome del Tenant. Il nome \"#{tenant.name}\" è già in uso."
            )
          end

          match = tenant.name =~ /^#{existing.name}/
          match ||= existing.name =~ /^#{tenant.name}/
          next unless match

        end

        tenants << tenant
      end

      def setup!
        raise "Il modulo Federa è già stato inizializzato!" if initialized?

        @initialized = true
        tenants.each(&:setup!)
      end

      def find_tenant(name)
        Decidim::Federa.tenants.select { |a| a.name == name}.try(:first)
      end

      private

      def initialized?
        @initialized
      end
    end

    class TenantSameName < StandardError; end

    class InvalidTenantName < StandardError; end
  end
end
