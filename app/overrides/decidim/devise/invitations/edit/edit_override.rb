Deface::Override.new(virtual_path: "decidim/devise/invitations/edit",
                     name: "add-federa-login",
                     surround: "div.wrapper") do
  '
  <%- if current_organization.enabled_omniauth_providers.keys.include?(:federa) %>
    <div class="wrapper">
      <div class="row collapse">
        <div class="row collapse">
          <div class="columns large-8 large-centered text-center page-title">
            <h1><%= t "decidim.federa.devise.invitations.edit.header" %></h1>

            <p><%= t("decidim.federa.devise.invitations.edit.subtitle").html_safe %></p>
          </div>
        </div>

        <% size = current_organization.enabled_omniauth_providers.dig(:federa, :button_size).try(:to_sym) %>
        <%- if current_organization.enabled_omniauth_providers.keys.include?(:federa) %>
          <div class="row">
            <div class="columns large-6 medium-10 medium-centered">
              <%= button_to decidim_federa.send("user_#{current_organization.enabled_omniauth_providers.dig(:federa, :tenant_name)}_omniauth_authorize_path"),
              class: "button button--social button--#{normalize_provider_name(:federa)}", form_class: "button--#{size}" do %>
                  <%= t("devise.shared.links.sign_in_with_provider_federa") %>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  <% else %>
    <%= render_original %>
  <% end %>
'
end