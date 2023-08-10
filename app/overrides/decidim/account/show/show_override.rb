Deface::Override.new(virtual_path: "decidim/account/show",
                     name: "remove-change-password-with-federa",
                     replace: "erb[silent]:contains('if current_organization.sign_in_enabled?')",
                     closing_selector: "erb[silent]:contains('end')" ) do
"
  <% if current_organization.sign_in_enabled? && !current_user.must_log_with_federa? %>
    <p>
      <a data-toggle='passwordChange' class='change-password'><%= t '.change_password' %></a>
    </p>
    <div id='passwordChange' class='toggle-show' data-toggler='.is-expanded'>
      <%= render partial: 'password_fields', locals: { form: f } %>
    </div>
  <% end %>
"
end

Deface::Override.new(virtual_path: "decidim/account/show",
                     name: "disable-email-when-is-a-federa-account",
                     replace: "erb:contains('f.email_field :email')") do
  "
  <%= f.email_field :email, readonly: session['decidim-federa.tenant'].present? %>
  "
end