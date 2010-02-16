class Admin::DownloadableSettingsController < Admin::BaseController
  def index
    @available_fields = %w{download_limit link_ttl}
  end
  
  def edit
    @edit_field = params[:id]
  end
  
  def update
    Spree::Config.set(params[:id].to_sym => params[:field_value].to_i)
    redirect_to admin_downloadable_settings_path
  end
end
