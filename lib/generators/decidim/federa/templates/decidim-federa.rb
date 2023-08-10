# frozen_string_literal: true

Decidim::Federa.configure do |config|
  # Definisce il nome del tenant. Solo lettere minuscole e underscores sono permessi.
  # Default: federa. Quando hai multipli tenant devi definire un nome univoco rispetto ai vari tenant.
  config.name = "<%= tenant_name %>"

  # Provider metadata file
  # config.idp_metadata_file = nil
  # Provider metadata url. Default: FedERa in secrets.yml
  ## Production: https://federa.lepida.it/gw/metadata'
  ## Staging: 'https://federatest.lepida.it/gw/metadata'
  config.idp_metadata_url = Rails.application.secrets.omniauth[:federa][:metadata]

  # Definisce l'entity ID del service provider:
  # config.sp_entity_id = "https://www.example.org/users/auth/federa/metadata"
  config.sp_entity_id = "<%= entity_id %>"

  # Certificato in stringa
  config.certificate = ""

  # Percorso relativo alla root dell"app del certificato
  config.certificate_file = ".keys/certificate.pem"

  # Chiave privata in stringa
  config.private_key = ""

  # Percorso relativo alla root dell'app della chiave privata
  config.private_key_file = ".keys/private_key.pem"

  # Nuovo certificato in stringa
  config.new_certificate = ""

  # Percorso relativo alla root dell'app del nuovo certificato
  config.new_certificate_file = ".keys/new_certificate.pem"

  #todo: verificare
  # Le chiavi che verranno salvate sul DB nell'autorizzazione
  config.metadata_attributes = {
    name: "name",
    surname: "familyName",
    fiscal_code: "fiscalNumber",
    gender: "gender",
    birthday: "dateOfBirth",
    birthplace: "placeOfBirth",
    company_name: "companyName",
    registered_office: "registeredOffice",
    iva_code: "ivaCode",
    id_card: "idCard",
    mobile_phone: "mobilePhone",
    email: "email",
    address: "address",
    digital_address: "digitalAddress"
  }

  # Extra metadata da include nel metadata. Esempio:
  #
  # Decidim::Federa.configure do |config|
  #   # ...
  #   config.sp_metadata = [
  #     {
  #       name: "Organization",
  #       children: [
  #         {
  #           name: "OrganizationName",
  #           attributes: { "xml:lang" => "en-US" },
  #           content: "Acme"
  #         }
  #       ]
  #     }
  #   ]
  # end

  # Configurare attributi necessari
  # config.attribute_services = [
  #   { name: "name", friendly_name: "Nome", is_required: true },
  #   { name: "familyName", friendly_name: "Cognome", is_required: true },
  #   { name: "fiscalNumber", friendly_name: "Codice Fiscale", is_required: true },
  #   { name: "spidCode", friendly_name: "Codice SPID", is_required: true },
  #   { name: "email", friendly_name: "Email", is_required: true },
  #   { name: "gender", friendly_name: "Genere", is_required: true },
  #   { name: "dateOfBirth", friendly_name: "Data di nascita", is_required: true },
  #   { name: "placeOfBirth", friendly_name: "Luogo di nascita", is_required: true },
  #   { name: "registeredOffice", friendly_name: "registeredOffice", is_required: true },
  #   { name: "ivaCode", friendly_name: "Partita IVA", is_required: true },
  #   { name: "idCard", friendly_name: "ID Carta", is_required: true },
  #   { name: "mobilePhone", friendly_name: "Numero di telefono", is_required: true },
  #   { name: "address", friendly_name: "Indirizzo", is_required: true },
  #   { name: "digitalAddress", friendly_name: "Indirizzo digitale", is_required: true }
  # ]


end