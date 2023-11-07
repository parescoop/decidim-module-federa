Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "remove-instructions-sessions-federa",
                     remove: "erb:contains('if current_organization.sign_up_enabled?')",
                     closing_selector: "erb[silent]:contains('end')" )

Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "append-instructions-sessions-federa",
                     insert_after: "erb:contains('current_organization.sign_in_enabled?')") do
  '
  <div class="row collapse">
    <div class="columns large-5 large-centered text-center page-title">
      <p>
        <% if current_organization.sign_up_enabled? %>
          <%= t("decidim.federa.omniauth_callbacks.new.federa_sessions_help", link: link_to(t("decidim.devise.registrations.new.sign_up").try(:downcase), new_user_registration_path)).html_safe %>
        <% elsif current_organization.sign_in_enabled? %>
          <p>
            <%= t(".sign_up_disabled") %>
          </p>
        <% else %>
          <p>
            <%= t(".sign_in_disabled") %>
          </p>
        <% end %>
      </p>
    </div>
  </div>
'
end