ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'pages', :action => 'index'
  
  map.swinburne '/swinburne', :controller => 'swinburne', :action => 'index'
  map.swinburne_poem '/swinburne/:poem_slug', :controller => 'swinburne', :action => 'poem'
  map.swinburne_poem_page '/swinburne/:poem_slug/:page', :controller => 'swinburne', :action => 'poem_page'
  
end