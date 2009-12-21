ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'pages', :action => 'index'
  
  map.swinburne 'swinburne', :controller => 'swinburne', :action => 'index'
  
  map.swinburne_poem 'swinburne/poems/:poem_id', :controller => 'swinburne', :action => 'poem'
  map.swinburne_poem_page 'swinburne/poems/:poem_id/:page', :controller => 'swinburne', :action => 'poem_page'
  
  map.swinburne_variant 'swinburne/:variant_id', :controller => 'swinburne', :action => 'variant'
  map.swinburne_variant_poem 'swinburne/:variant_id/:poem_id', :controller => 'swinburne', :action => 'variant_poem'
  map.swinburne_variant_poem_page 'swinburne/:variant_id/:poem_id/:page', :controller => 'swinburne', :action => 'variant_poem_page'
  
end