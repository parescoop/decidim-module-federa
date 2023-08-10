

# Aggiunge nel pannello di amministrazione /system la scadenza dei certificati a titolo informativo del sistemista
Deface::Override.new(virtual_path: "decidim/system/organizations/_omniauth_provider",
                     name: "add-certificate-expiration",
                     insert_bottom: "div.card-section") do
  '
  <% if provider == :federa && (tenant = Decidim::Federa.tenants.find { |t| t.name == f.object.try(:omniauth_settings_federa_tenant_name) } ) %>
    <% if tenant.certificate.present? && (c = OpenSSL::X509::Certificate.new(tenant.certificate) rescue nil)  %>
        <p class="help-text"><%= t("certificate", scope: "#{i18n_scope}.#{provider}", date: c.not_after) %></p>
    <% end %>
    <% if tenant.new_certificate.present? && (nc = OpenSSL::X509::Certificate.new(tenant.new_certificate) rescue nil)  %>
      <p class="help-text"><%= t("new_certificate", scope: "#{i18n_scope}.#{provider}", date: nc.not_after) %></p>
    <% end %>
  <% end %>
'
end