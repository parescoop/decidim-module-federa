

# Aggiunge badge SPID o CIE agli utenti nel backoffice che hanno utilizzato
# queste autorizzazioni
Deface::Override.new(virtual_path: "decidim/admin/officializations/index",
                     name: "add-badge-spid",
                     insert_before: 'div.card-section tbody tr td erb[loud]:contains("translated_attribute(user.officialized_as)")') do
'
  <%= user.must_log_with_spid? ? federa_icon : "" %>
'
end