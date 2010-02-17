# Route for download files from simple user, must need secret and filename
map.download_file '/download/:secret/:filename', :controller => :downloadables, 
                                                 :action => :show,
                                                 :requirements => { :secret => /\S{16}/,
                                                                    :filename => /.+/
                                                                  }


                                                 

map.namespace :admin do |admin|
  admin.resources :products, :has_many => [:downloadables]
  admin.resources :downloadable_settings
end  

# map.resources :downloadables
