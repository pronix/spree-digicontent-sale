# -*- coding: utf-8 -*-
class DigicontentSaleExtension < Spree::Extension
  version "1.2"
  description "Downloadable products"
  url "http://github.com/pronix/spree-digicontent-sale"
  
  # Need to pack a downloadable file in one zip archive
  def self.require_gems(config)
    config.gem 'rubyzip', :lib => 'zip/zip', :version => '0.9.1'
  end
  
  def activate
    
    ShippingMethod.class_eval do
      class << self
        def download
          find_by_name('Download')
        end
      end
    end
    
    Address.class_eval do
      class << self
        def download
          find(66)
        end
      end
    end
    
    LineItem.class_eval do
      before_update :fix_quantity_downloadables
      
      # If product is downloadables max quanity for it is 1
      def fix_quantity_downloadables
        self.quantity = 1 if self.product.downlodables?
      end
    end
    
    # Need a global peference for download limits
    AppConfiguration.class_eval do 
      preference :download_limit, :integer, :default => 0 # 0 for unlimited
      preference :link_ttl, :integer, :default => 24 # Download link ttl, 0 for unlimited
    end
    
    Product.class_eval do 
      has_many :downloadables, :as => :viewable, :order => :position, :dependent => :destroy
      
      # Check if product has a files for download
      def downlodables?
        true if !self.downloadables.empty?
      end
    end
    
    Variant.class_eval do 
       has_many :downloadables, :as => :viewable, :order => :position, :dependent => :destroy
    end
    
    LineItem.class_eval do 
      before_create :add_default_staff
      
      # Add some staff to line_item when it's create
      def add_default_staff
        self.download_code = random_password if self.variant.product.downlodables?
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
    
    Checkout.class_eval do
      # help method to determine that all line_items in checkout are downloadables
      def only_downloadables?
        return true if !self.order.line_items.map {|x| x.product.downlodables?}.include?(nil)
      end
    end
    
    OrderMailer.class_eval do
      # For render_links
      helper :application 
      
      # For url_for :host 
      default_url_options[:host] = Spree::Config[:site_url]
    end
    
    ApplicationHelper.class_eval do
      # Maybe delete?
      def generate_secret(record)
        Digest::MD5.hexdigest("#{record.id}-#{ActionController::Base.session_options[:secret]}")
      end
      
      def only_downloadable?(checkout)
        return true if !checkout.order.line_items.map {|x| x.product.downlodables?}.include?(nil)
      end
    end
    
    CheckoutsHelper.class_eval do
      
      # Fix default method, becouse when products only downloadables user don't want
      # to see address and delivery bars
      def checkout_progress
        if only_downloadable?(@checkout)
          none_use = ['address', 'delivery']
          checkout_fix = Checkout.state_names.map.delete_if {|x| none_use.include?(x)}
        else
          checkout_fix = Checkout.state_names.map
        end
        steps = checkout_fix.map do |state|
          text = t("checkout_steps.#{state}")
          css_classes = []
          current_index = Checkout.state_names.index(@checkout.state)
          state_index = Checkout.state_names.index(state)
          if state_index < current_index
            css_classes << 'completed'
            text = link_to text, edit_order_checkout_url(@order, :step => state)
          end
          css_classes << 'next' if state_index == current_index + 1
          css_classes << 'current' if state == @checkout.state
          css_classes << 'first' if state_index == 0
          css_classes << 'last' if state_index == Checkout.state_names.length - 1

          # It'd be nice to have separate classes but combining them with a dash helps out for IE6 which only sees the last class
          content_tag('li', content_tag('span', text), :class => css_classes.join('-'))
        end
        content_tag('ol', steps.join("\n"), :class => 'progress-steps', :id => "checkout-step-#{@checkout.state}") + '<br clear="left" />'
      end
    end
    
    CheckoutsController.class_eval do
      before_filter :change_checkout_shipping
      
      def change_checkout_shipping
        # If object is nil don't do anything
        return if @object.nil?
        if @object.try(:only_downloadables?)
          # Its ugly and special for multishop
          @object.shipping_method = ShippingMethod.find_by_name('По умолчанию')
          @object.ship_address = Address.download
          @object.bill_address = Address.download
        end
      end
    end  
    
    # Paperclip configuration
    Paperclip.interpolates(:secret) do |attachment, style|
      Digest::MD5.hexdigest("#{attachment.instance.id}-#{ActionController::Base.session_options[:secret]}")
    end
  
  end
end
