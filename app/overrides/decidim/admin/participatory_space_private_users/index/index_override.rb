Deface::Override.new(virtual_path: "decidim/admin/participatory_space_private_users/index",
                     name: "add-badge-federa-header-to-private-users",
                     insert_before: 'div.card-section thead tr th.actions') do
  '
  <th><%= t("decidim.admin.officializations.index.badge") %></th>
'
end

Deface::Override.new(virtual_path: "decidim/admin/participatory_space_private_users/index",
                     name: "add-badge-federa-to-private-users",
                     insert_before: 'div.card-section tbody tr td.table-list__actions') do
  '
  <td><%= private_user.user.must_log_with_federa? ? federa_icon : "" %>
'
end