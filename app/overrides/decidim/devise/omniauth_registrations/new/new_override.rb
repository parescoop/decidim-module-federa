Deface::Override.new(virtual_path: "decidim/devise/omniauth_registrations/new",
                     name: "disable-email-field",
                     replace: "erb:contains('f.email_field :email')") do
  '
<%= f.email_field :email, readonly: session["decidim-federa.tenant"].present? %>
<%= f.hidden_field :raw_data %>
'
end