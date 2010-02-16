map.namespace :admin do |admin|
  admin.resources :products, :has_many => [:downloadables]
  admin.resources :downloadable_settings
end  

map.download_file '/file/:secret/:filename', :controller => :downloadables,
                                             :action => :show, 
                                             :conditions => { :method => :get }
# map.resources :downloadables
