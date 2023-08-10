Deface::Override.new(virtual_path: "decidim/devise/shared/_omniauth_buttons",
                     name: "add-provider-button-federa",
                     insert_after: "erb[silent]:contains('current_organization.enabled_omniauth_providers.keys.each do |provider|')") do
  '
    <%- if provider == :federa %>
      <% size = current_organization.enabled_omniauth_providers.dig(:federa, :button_size).presence || "m" %>
      <%= button_to decidim_federa.send("user_#{current_organization.enabled_omniauth_providers.dig(:federa, :tenant_name)}_omniauth_authorize_path"),
          class: "button button--social button--#{normalize_provider_name(provider)}", form_class: "button--#{size}" do %>
          <%= t("devise.shared.links.sign_in_with_provider_federa") %>
      <% end %>
      <% next %>
    <% end %>
'
end