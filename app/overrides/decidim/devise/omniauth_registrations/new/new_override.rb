Deface::Override.new(virtual_path: "decidim/devise/omniauth_registrations/new",
                     name: "disable-email-field-federa",
                     replace: "erb:contains('f.email_field :email')") do
  '
<%= f.email_field :email, readonly: session["decidim-federa.tenant"].present? && f.object.email.present? %>
<%= f.hidden_field :raw_data %>
<%= f.hidden_field :invitation_token %>
<div class="card" id="card__newsletter">
  <div class="card__content">
    <h3><%= t("decidim.devise.registrations.new.newsletter_title") %></h3>
      <div class="field">
        <%= f.check_box :newsletter, label: t("decidim.devise.registrations.new.newsletter"), checked: f.object.newsletter %>
      </div>
  </div>
</div>
'
end