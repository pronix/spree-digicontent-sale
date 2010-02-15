class DownloadableHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_configurations_menu do
    "<tr><td><%= link_to t(\"downloadable_settings\"), admin_downloadable_settings_path %></td><td>
     <%= t(\"downloadable_settings_description\") %></td></tr>"
  end
end
