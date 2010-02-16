map.namespace :admin do |admin|
  admin.resources :products, :has_many => [:downloadables]
  admin.resource :downloadable_settings
end  

map.resources :downloadables
