class DownloadablesController < Spree::BaseController  
  # Download file
  def show
    unless LineItem.find_by_download_code(params[:secret])
      flash[:error] = t('file_with_this_code_not_found')
      redirect_to root_path
    else
      item = LineItem.find_by_download_code(params[:secret])
      unless item.available_link?
        flash[:error] = t('time_expired')
        redirect_to root_path and return
      end
      unless item.product.downloadables.find_by_attachment_file_name(params[:filename])
        flash[:error] = t('file_not_found')
        redirect_to root_path and return
      end
      filepath = item.product.downloadables.first.attachment.path
      item.product.downloadables.first.increment!(:downloads_count)
      send_file filepath 
    end
  end
end
