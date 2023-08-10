

# Aggiunge il tenant name all'autorizzazione
Deface::Override.new(virtual_path: "decidim/system/organizations/edit",
                     name: "add-tenant-name",
                     replace: "erb:contains('f.collection_check_boxes :available_authorizations, Decidim.authorization_workflows, :name, :description')") do
  '
  <%= f.collection_check_boxes :available_authorizations, Decidim.authorization_workflows, :name, :system_name %>
  '
end