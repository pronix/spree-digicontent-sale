class DownloadableHooks < Spree::ThemeSupport::HookListener
  # I think this is not necessary
  insert_after :admin_configurations_menu do
    "<tr><td><%= link_to t(\"downloadable_settings\"), admin_downloadable_settings_path %></td><td>
     <%= t(\"downloadable_settings_description\") %></td></tr>"
  end

  # Delete variants from admin product tabs
  # TODO: letter try to many varinants for one product, for example:
  # Original film has a many format - mov, avi and else
  # replace :admin_product_tabs, 'admin/shared/download_tabs'
  insert_after :admin_product_tabs, 'admin/shared/download_tabs'
  
  # Delete none need field from product admin edit
  replace :admin_product_form_right, 'admin/products/downloable_product_form'
  
  # When product has a downloadables we render some slightly different
  # html templates
  # replace :inside_product_cart_form, 'shared/show_price'
  # replace :cart_item_quantity, 'shared/cart_item_quanity'
  
  # Remove qty in order page
  # remove :cart_item_quantity

  # Replace qty in checkout page
  # replace :order_details_line_item_row, 'shared/order_details_line_item_row'
  
end
