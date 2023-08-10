require 'decidim/federa/secret_modifier'

module Decidim
  module Federa
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        desc "Crea un Decidim FedERa Tenant"

        argument :tenant_name, type: :string
        argument :entity_id, type: :string

        def copy_initializer
          if Decidim::Federa.tenants.map(&:name).include?(tenant_name)
            say_status(:conflict, "Esiste già un tenant con questo nome", :red)
            exit
          end
          say_status(:conflict, "Il nome del tenant FedERa può contenere solo lettere o underscore.", :red) && exit unless tenant_name.match?(/^[a-z_]+$/)
          template "decidim-federa.rb", "config/initializers/decidim-federa-#{tenant_name}.rb"
        end

        def enable_authentication
          secrets_path = Rails.application.root.join("config", "secrets.yml")
          secrets = YAML.safe_load(File.read(secrets_path), [], [], true)

          if secrets.dig("default", "omniauth", "federa")
            say_status :identical, "config/secrets.yml", :blue
          else
            mod = SecretsModifier.new(secrets_path, tenant_name)
            final = mod.modify

            target_path = Rails.application.root.join("config", "secrets.yml")
            File.open(target_path, "w") { |f| f.puts final }

            say_status :insert, "config/secrets.yml", :green
          end
          say_status :skip, "Ricorda di modificare config/secrets.yml omniauth se le configurazioni di :default non sono incluse", :yellow
        end

        def locales
          template "federa.en.yml", "config/locales/federa-#{tenant_name}.en.yml"
          template "federa.it.yml", "config/locales/federa-#{tenant_name}.it.yml"
          say_status :skip, "Completa le traduzione con le lingue disponibili config/locales/federa-#{tenant_name}.en.yml", :yellow
        end

        def organizations
          say_status :skip, "Ricorda di associare le organizzazioni con il relativo tenant in amministrazione", :yellow
        end

        def certificate
          say_status :skip, "Ricorda di generare il certificato e la chiave privata da aggiungere in config/initializers/decidim-federa-#{tenant_name}.rb", :yellow
        end

      end

    end
  end
end