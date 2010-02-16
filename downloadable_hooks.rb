class DownloadableHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_configurations_menu do
    "<tr><td><%= link_to t(\"downloadable_settings\"), admin_downloadable_settings_path %></td><td>
     <%= t(\"downloadable_settings_description\") %></td></tr>"
  end
  
  insert_after :admin_product_tabs do
    "<li<%= \' class=\"active\"\' if current == \"Downloadables\" %>>
     <%= link_to t(\"product_files\"), admin_product_downloadables_path(@product) %>
     </li>"
  end
  
  # When product has a downloadables we render some slightly different
  # html templates
  replace :inside_product_cart_form, 'shared/show_price'
  replace :cart_item_quantity, 'shared/cart_item_quanity'
  
  
end