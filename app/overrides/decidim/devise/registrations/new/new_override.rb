Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "remove-instructions-federa",
                     replace_contents: "div.row.collapse div.row.collapse div.page-title") do
  '
    <h1><%= t(".sign_up") %></h1>
  '
end

Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "append-instructions-federa",
                     insert_before: "erb:contains('decidim_form_for')") do
  '
    <%- if current_organization.enabled_omniauth_providers.dig(:federa).present? %>
      <div class="columns large-10 large-centered text-center page-title">
        <p>
          <%= t("decidim.federa.omniauth_callbacks.new.federa_help", link: link_to(t("decidim.devise.registrations.new.sign_in").try(:downcase), new_user_session_path)).html_safe %>
        </p>
      </div>
    <% end %>
'
end