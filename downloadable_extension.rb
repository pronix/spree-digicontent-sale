# require_dependency 'application'
#require_dependency 'application_controller'

class DownloadableExtension < Spree::Extension
  version "1.1"
  description "Downloadable products"
  url "http://github.com/rocket-rentals/downloadable"
  
  def self.require_gems(config)
    config.gem 'rubyzip', :lib => 'zip/zip', :version => '0.9.1'
  end
  
  def activate
    Checkout.state_machines[:state] = StateMachine::Machine.new(Checkout, :initial => 'payment') do
      after_transition :to => 'complete', :do => :complete_order
      before_transition :to => 'complete', :do => :process_payment
      event :next do
        transition :to => 'complete', :from => 'payment'
      end
    end
    
    CheckoutsController.class_eval do
      def object
        return @object if @object
        @object = parent_object.checkout
        unless params[:checkout] and params[:checkout][:coupon_code]
          @object.creditcard ||= Creditcard.new(:month => Date.today.month, :year => Date.today.year)
          @object.shipping_method ||= ShippingMethod.first
        end
        @object
      end
      
    end  

    
    # Need a global peference for download limits
    AppConfiguration.class_eval do 
      preference :download_limit, :integer, :default => 0 # 0 for unlimited
    end
    
    # Global/General Settings for all product downloads
    Admin::ConfigurationsController.class_eval do
      before_filter :add_product_download_settings_links, :only => :index

      def add_product_download_settings_links
        @extension_links << {:link => admin_downloadable_settings_path, :link_text => t('downloadable_settings'), 
          :description => "Configure general product download settings."}
      end
    end
    
    Admin::ProductsController.class_eval do
      after_filter :show_flash, :only => :edit
      
      # Show notice when product don't hava a attached files
      def show_flash
        flash[:notice] = t('product_must_have_attached_file') if @product.downloadables.empty?
      end
    end
    
    
    # ----------------------------------------------------------------------------------------------------------
    # Model class_evals 
    # ----------------------------------------------------------------------------------------------------------
    
    Product.class_eval do 
      has_many :downloadables, :as => :viewable, :order => :position, :dependent => :destroy
      
      # ReWrite a named_scope, now he selects on product who has files.
      named_scope :available, :conditions => ["products.available_on <= ? 
                                               AND products.id IN (SELECT viewable_id FROM product_downloads)", Time.zone.now]
    end
    
    Variant.class_eval do 
       has_many :downloadables, :as => :viewable, :order => :position, :dependent => :destroy
    end
    
    
    LineItem.class_eval do 
      before_create :add_download_limit
      
      # Insert download limit to line items for orders
      def add_download_limit
        use_global = false
        
        if !self.variant.nil? and !self.variant.downloadables.empty?
          if self.variant.downloadables.first.download_limit.nil?
            use_global = true
          else
            self.download_limit = self.variant.downloadables.first.download_limit
          end
        elsif !self.variant.product.nil? and !self.variant.product.downloadables.empty?
          if self.variant.product.downloadables.first.download_limit.nil?
            use_global = true
          else
            self.download_limit = self.variant.product.downloadables.first.download_limit
          end
        end
        
        if((Spree::Config[:download_limit] != 0) && use_global)
          self.download_limit = Spree::Config[:download_limit]
        end
      end
      
    end
    
    OrderMailer.class_eval do
      # For render_links
      helper :application 
      
      # For url_for :host 
      default_url_options[:host] = Spree::Config[:site_url]
    end
    
    ShippingMethod.class_eval do
      class << self
        def download
          self.find_by_name('Download')
        end
      end
    end
    
    # ----------------------------------------------------------------------------------------------------------
    # End for Models
    # ----------------------------------------------------------------------------------------------------------
    
    # ----------------------------------------------------------------------------------------------------------
    # Helper class_evals
    # ----------------------------------------------------------------------------------------------------------
    ApplicationHelper.class_eval do
      # Checks if checkout cart has ONLY downloadable items
      # Used for shipping in helpers/checkouts_helper.rb
      def only_downloadable
        downloadable_count = 0
        @order.line_items.each do |item|
          if((!item.product.downloadables.empty?) || (!item.variant.downloadables.empty?))
            downloadable_count += 1
          end
        end
        @order.line_items.size == downloadable_count
      end
      
      def has_downloadable?
        @order.line_items.each do |item|
          return true if ((!item.product.downloadables.empty?) || (!item.variant.downloadables.empty?))
        end
      end
      
      def render_links(item, options={:html => true})
        if options[:html] == false
          return t(:download) + ': ' + downloadable_url(item, :s => generate_secret(item))
        elsif !item.product.downloadables.empty?
          return content_tag(:sub,t(:download) + ': ' + link_to("#{item.product.downloadables.first.filename}", downloadable_url(item, :s => generate_secret(item))))
        elsif !item.variant.downloadables.empty?
          return content_tag(:sub,t(:download) + ': ' + link_to("#{item.variant.downloadables.first.filename}", downloadable_url(item, :s => generate_secret(item))))
        end
      end
      
      def generate_secret(record)
        Digest::MD5.hexdigest("#{record.id}-#{ActionController::Base.session_options[:secret]}")
      end
    end
    # ----------------------------------------------------------------------------------------------------------
    # End for Helpers 
    # ----------------------------------------------------------------------------------------------------------   

    # ----------------------------------------------------------------------------------------------------------
    # Configure Paperclip
    # ----------------------------------------------------------------------------------------------------------   
    Paperclip.interpolates(:secret) do |attachment, style|
      Digest::MD5.hexdigest("#{attachment.instance.id}-#{ActionController::Base.session_options[:secret]}")
    end
    # ----------------------------------------------------------------------------------------------------------
    # End for Paperclip Configuration
    # ----------------------------------------------------------------------------------------------------------   
  
  end
end
