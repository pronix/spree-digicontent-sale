class DownloadableExtension < Spree::Extension
  version "1.2"
  description "Downloadable products"
  url "http://github.com/pronix/spree-digicontent-sale"
  
  # Need to pack a downloadable file in one zip archive
  def self.require_gems(config)
    config.gem 'rubyzip', :lib => 'zip/zip', :version => '0.9.1'
  end
  
  def activate
    
    # Need a global peference for download limits
    AppConfiguration.class_eval do 
      preference :download_limit, :integer, :default => 0 # 0 for unlimited
      preference :link_ttl, :integer, :default => 24 # Download link ttl, 0 for unlimited
    end
    
    Product.class_eval do 
      has_many :downloadables, :as => :viewable, :order => :position, :dependent => :destroy
      # named_scope :available, :conditions => ['products.available_on <= ?', Time.zone.now]
    end
    
    Variant.class_eval do 
       has_many :downloadables, :as => :viewable, :order => :position, :dependent => :destroy
    end
    
    LineItem.class_eval do 
      before_update :fix_quantity
      before_create :add_default_staff
      
      # Fuck, it's ugly, but I don't know how use it before_update {self.quantity = 1}
      def fix_quantity
        self.quantity = 1
      end
      
      # Add some staff to line_item when it's create
      def add_default_staff
        # Letter add download_limit
        # if((Spree::Config[:download_limit] != 0) && use_global)
        #   self.download_limit = Spree::Config[:download_limit]
        # end
        self.download_code = random_password
      end
      
      # Check if link is not die
      def available_link?
        return true if (self.created_at + Spree::Config[:link_ttl].hours) >= Time.now
      end
      
      private
      
      # Generate some random code from files
      def random_password(size=16)
        chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
        (1..size).collect{|a| chars[rand(chars.size)] }.join
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
        # Use thid method to shipping_method_id
        def download
          self.find_by_name('Download')
        end
      end
    end
    
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
      
      def generate_secret(record)
        Digest::MD5.hexdigest("#{record.id}-#{ActionController::Base.session_options[:secret]}")
      end
    end
    
    # Paperclip configuration
    Paperclip.interpolates(:secret) do |attachment, style|
      Digest::MD5.hexdigest("#{attachment.instance.id}-#{ActionController::Base.session_options[:secret]}")
    end
  
  end
end
