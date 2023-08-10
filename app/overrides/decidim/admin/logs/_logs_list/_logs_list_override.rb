

# Agginge filtri di ricerca per i log
Deface::Override.new(virtual_path: "decidim/admin/logs/_logs_list",
                     name: "add-log_filters",
                     insert_before: "ul.logs.table" ) do
  '
  <% if controller_name == "logs" %>
    <%= render partial: "decidim/admin/shared/identity_filters", locals: { i18n_ctx: nil } %>
  <% end %>
  '
end

Deface::Override.new(virtual_path: "decidim/admin/logs/_logs_list",
                     name: "add-log_filters-no-results",
                     insert_before: "div.logs.table" ) do
  '
  <% if controller_name == "logs" %>
    <%= render partial: "decidim/admin/shared/identity_filters", locals: { i18n_ctx: nil } %>
  <% end %>
  '
end