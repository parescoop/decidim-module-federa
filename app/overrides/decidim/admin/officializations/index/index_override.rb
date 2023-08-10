Deface::Override.new(virtual_path: "decidim/admin/officializations/index",
                     name: "add-badge-federa",
                     insert_before: 'div.card-section tbody tr td erb[loud]:contains("translated_attribute(user.officialized_as)")') do
'
  <%= user.must_log_with_federa? ? federa_icon : "" %>
'
end