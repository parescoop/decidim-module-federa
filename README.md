# Decidim FedERa
Autenticazione FedERa per Decidim v0.26.x. Questa gemma si appoggia: [ruby-saml](https://github.com/onelogin/ruby-saml), [decidim](https://github.com/decidim/decidim/tree/v0.25.2) e [omniauth](https://github.com/omniauth/omniauth).

Ispirata a [decidim-msad](https://github.com/mainio/decidim-module-msad).

## Installazione
Aggiungi al tuo Gemfile

```ruby
gem 'decidim-federa'
```

ed esegui dal terminale
```bash
$ bundle install
$ rails generate decidim:federa:install TENANT_NAME ENTITY_ID
$ bundle exec rake assets:precompile
# Ripetere l'installer per ogni tenant di cui si ha bisogno.
```
Sostituire TENANT_NAME con una stringa univoca che identifica il tenant e ENTITY_ID con un identificativo (URI) univoco dell'entità FedERa.
Il TENANT_NAME deve essere univoco anche tra FedERa.

Verranno generati:
1. `config/initializers/decidim-federa-#{tenant_name}.rb` per configurare FedERa ad ogni installazione.
2`verrà automaticamente aggiunto in `config/secrets.yml` nel blocco default la configurazione `omniauth` necessaria. Aggiungere la configurazione ai vari environment a seconda delle esigenze.
3`config/locales/federa-#{tenant_name}.en.yml` con le etichette necessarie. Duplicare per ogni locale necessaria.

Per modificare o eliminare un tenant è sufficiente modificare o cancellare proprio il file generato in initializers e fare un restart del server.
Qualora si voglia eliminare la gemma è sufficiente eliminare o ripristinare i file generati degli step precedenti.

## Configurazione
Associare nel pannello di amministratore di sistema (/system) il `tenant_name` ad ogni organizzazione FedERa.
Completare le configurazioni nell'`initializer` di ogni tenant.

```ruby
# config/initializers/decidim-federa-#{tenant_name}.rb
Decidim::Federa.configure do |config|
  #config ...
end
```
tramite il quale potete accedere alle seguenti configurazioni:

|Nome| Valore di default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Descrizione                                                                                                                                                                                                            |Obbligatorio|
|:---|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---|
|config.name| `'#{tenant_name}'`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Identificativo univoco di ogni tenant. Compilato automaticamente dall'installer                                                                                                                                        |✓|
|config.sp_entity_id| `'#{entity_id}'`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Identificativo univoco (URI) del Service Provider                                                                                                                                                                      |✓|
|config.metadata_attributes| `{ name: "name", surname: "familyName", fiscal_code: 'fiscalNumber', gender: 'gender', birthday: 'dateOfBirth', birthplace: "placeOfBirth", company_name: "companyName", registered_office: "registeredOffice", iva_code: "ivaCode", id_card: 'idCard', mobile_phone: 'mobilePhone', email: 'email', address: 'address', digital_address: 'digitalAddress' }`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Attibuti che verranno salvati all'autenticazione con relativo mapping                                                                                                                                                  ||
|config.private_key_file| `.keys/private_key.pem`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Percorso relativo alla root dell'app della chiave privata                                                                                                                                                              |✓|
|config.certificate_file| `.keys/certificate.pem`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Percorso relativo alla root dell'app del certificato. La data di scadenza verrà visualizzata nel pannello di amministratore di sistema (/system) una volta associato con il tenant_name.                               |✓|
|config.new_certificate_file| `nil`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Percorso relativo alla root dell'app del nuovo certificato in caso di sostituzione. La data di scadenza verrà visualizzata nel pannello di amministratore di sistema (/system) una volta associato con il tenant_name. ||
|config.sp_metadata| `[{ name: "Organization", children: [ { name: 'OrganizationName', content: 'Nome organizzazione S.p.a', attributes: { "xml:lang" => "it" }.{ name: 'OrganizationDisplayName', content: 'Nome organizzazione S.p.a', attributes: { "xml:lang" => "it" }.{ name: 'OrganizationURL', content: 'www.example.com', attributes: { "xml:lang" => "it" }]`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Configurazioni aggiuntive relative al service provider.                                                                                                                                                                |✓|
|config.spid_level| `2`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Il livello SPID richiesto dal tenant                                                                                                                                                                                   ||
|config.fields| `[{name:"nome",friendly_name:"Nome",is_required:true},{name:"cognome",friendly_name:"Cognome",is_required:true},{name:"CodiceFiscale",friendly_name:"Codice Fiscale",is_required:true},{name:"spidCode",friendly_name:"Codice SPID",is_required:true},{name:"emailAddressPersonale",friendly_name:"Email",is_required:true},{name:"sesso",friendly_name:"Genere",is_required:true},{name:"dataNascita",friendly_name:"Data di nascita",is_required:true},{name:"luogoNascita",friendly_name:"Luogo di nascita",is_required:true},{name:"registeredOffice",friendly_name:"registeredOffice",is_required:true},{name:"ivaCode",friendly_name:"Partita IVA",is_required:true},{name:"idCard",friendly_name:"ID Carta",is_required:true},{name:"cellulare",friendly_name:"Numero di telefono",is_required:true},{name:"indirizzoResidenza",friendly_name:"Indirizzo",is_required:true},{name:"emailAddress",friendly_name:"Indirizzo digitale",is_required:true}]` | Attributi richiesti all'Identity Provider. Configurazioni relative al service provider.                                                                                                                                |✓|
|config.authorization_handlers| `[]`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Permette di aggiungere altre autorizzazioni da eseguire successivamente a FedERa                                                                                                                                       ||


### URLs
Il metadata se non diversamente specificato in `config.metadata_path` viene esposto `/users/auth/#{tenant_name}/metadata`.

```bash
Routes for Decidim::Federa::Engine:
                       destroy_user_session DELETE|POST    /users/sign_out(.:format)                     decidim/federa/sessions#destroy
                  slo_callback_user_session GET            /users/slo_callback(.:format)                 decidim/federa/sessions#slo_callback
     user_#{tenant_name}_omniauth_authorize GET|POST       /users/auth/#{tenant_name}(.:format)          decidim/federa/omniauth_callbacks#passthru
      user_#{tenant_name}_omniauth_callback GET|POST       /users/auth/#{tenant_name}/callback(.:format) decidim/#{tenant_name}/omniauth_callbacks#federa
        user_#{tenant_name}_omniauth_create POST|PUT|PATCH /users/auth/#{tenant_name}/create(.:format)   decidim/federa/omniauth_callbacks#create
           user_#{tenant_name}_omniauth_slo GET|POST       /users/auth/#{tenant_name}/slo(.:format)      decidim/federa/sessions#slo
         user_#{tenant_name}_omniauth_spslo GET|POST       /users/auth/#{tenant_name}/spslo(.:format)    decidim/federa/sessions#spslo

Routes for Decidim::Federa::Verification::Engine:
                          new_authorization GET           /authorizations/new(.:format)                   decidim/federa/verification/authorizations#new
                                       root GET           /                                               decidim/federa/verification/authorizations#new

```

### Views
Il button "Entra con FedERa" automaticamente viene visualizzato nella pagina di login se l'autenticazione viene abilitata nel pannello di amministratore di sistema (/system).
Per renderizzare il button predefinito:

```ruby
<%= render partial: 'federa/federa', locals: { size: :m } %>
# button_size deve essere in [ :s, :m, :l, :xl]. Default: :m. Configurabile nel pannello di amministratore di sistema (/system) per ogni tenant.
```
Altrimenti è possibile customizzare la view creando il file app/views/decidim/federa/_federa.html.erb.

### Aggiornamento certificati
Per aggiornare il certificato del service provider senza interruzione del servizio, può essere utilizzato il parametro `new_certificate_file`. 
Questo pubblicherà il nuovo certificato nel metadata in modo che gli Identity Provider possano cachere il certificato.

Per esempio, se vuoi passare dal `CERT A` al `CERT B`, prima di sostituirlo le tue configurazioni dovrebbero essere come le seguenti.
Entrambi `CERT A` e `CERT B` compariranno nel SP metadata, e `CERT A` verrà utilizzato per firmare.

```ruby
  config.certificate_file = "CERT A"
  config.private_key_file = "PRIVATE KEY FOR CERT A"
  config.new_certificate_file = "CERT B"
```

Dopo che gli IdP avranno messo in cache `CERT B`, potrai aggiornare le configurazioni come di seguito:

```ruby
  config.certificate_file = "CERT B"
  config.private_key_file = "PRIVATE KEY FOR CERT B"
```
## Contributori
Gem sviluppata da [Kapusons](https://www.kapusons.it) per [Pares](https://pares.it).

## Segnalazioni sulla sicurezza
La gem utilizza tutte le raccomandazioni e le prescrizioni in materia di sicurezza previste da Decidim e dall’Agenzia per l’Italia Digitale per SPID. E' indispensabile contestualizzare e dettagliare con la massima precisione le segnalazioni. Le segnalazioni anonime o non sufficientemente dettagliate non potranno essere verificate.


## Licenza
Vedi [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt).