class DownloadablesController < Spree::BaseController  
  # require_user is a method in Application.rb
  # disabled to enable downloads for non-members     
  # before_filter :require_user, :only => :show
  
  ssl_required :show
  
  def show
    item = LineItem.find(params[:id])
    if Digest::MD5.hexdigest("#{item.id}-#{ActionController::Base.session_options[:secret]}") != params[:s]
      flash[:error] = t(:unauthorized_access)
      redirect_to order_url(item.order)
    elsif ((item.download_limit.nil? || (item.download_limit > 0))) 
      item.decrement!(:download_limit) if (!item.download_limit.nil?)
      
      filepath = ""
      if !item.product.downloadables.empty?
        filepath = item.product.downloadables.first.attachment.path
      elsif !item.variant.downloadables.empty?
        filepath = item.variant.downloadables.first.attachment.path
      end
      
      # In pratical use, enabled X-sendfile in your server flavor ie. Apache, lighty, etc.. 
      # DON'T use mongrel/webrick, since files are static. Resources will be wasted since it'll go thru the rails stack to 
      # fetch the file. Uncomment the line below.
      send_file filepath #, :x_sendfile => true
    else
      flash[:error] = t(:you_have_reached_your_download_limit)
      redirect_to order_url(item.order)
    end
  end
end
