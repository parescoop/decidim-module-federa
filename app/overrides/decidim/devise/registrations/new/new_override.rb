Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "append-instructions-federa",
                     insert_before: "erb:contains('decidim_form_for')") do
  '
    <div class="columns large-10 large-centered text-center page-title">
      <p>
        <%= t("decidim.federa.omniauth_callbacks.new.federa_help", link: link_to(t("decidim.devise.registrations.new.sign_in").try(:downcase), new_user_session_path)).html_safe %>
      </p>
    </div>
'
end


Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "remove-instructions-federa",
                     remove: "div.row.collapse div.row.collapse div.page-title p")