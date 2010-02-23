class DownloadableHooks < Spree::ThemeSupport::HookListener
  # Configuaradion download settings in admin panel
  insert_after :admin_configurations_menu do
    "<tr><td><%= link_to t(\"downloadable_settings\"), admin_downloadable_settings_path %></td><td>
     <%= t(\"downloadable_settings_description\") %></td></tr>"
  end

  # Add downloadable tabs for product
  insert_after :admin_product_tabs, 'admin/shared/download_tabs'
  
  # Fix add to cart step. When product has a file we hidden 
  # count field
  replace :inside_product_cart_form, 'products/download_cart'
  
  # When product has a downloadables we render some slightly different
  # html templates
  # replace :inside_product_cart_form, 'shared/show_price'
  
  # Remove qty in order page
  # remove :cart_item_quantity

  # Replace qty in checkout page
  # replace :order_details_line_item_row, 'shared/order_details_line_item_row'
  
end
