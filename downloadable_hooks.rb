class DownloadableHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_configurations_menu do
    "<tr><td><%= link_to t(\"downloadable_settings\"), admin_downloadable_settings_path %></td><td>
     <%= t(\"downloadable_settings_description\") %></td></tr>"
  end

  # Delete variants from admin product tabs
  # TODO: letter try to many varinants for one product, for example:
  # Original film has a many format - mov, avi and else
  replace :admin_product_tabs, 'admin/shared/download_tabs'
  
  # When product has a downloadables we render some slightly different
  # html templates
  replace :inside_product_cart_form, 'shared/show_price'
  replace :cart_item_quantity, 'shared/cart_item_quanity'
  
  
end
