ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'pages', :action => 'index'
  map.resources :swinburne, :only=>[:index, :show]
end