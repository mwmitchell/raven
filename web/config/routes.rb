ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'pages', :action => 'index'
  
  map.swinburne '/swinburne', :controller => 'swinburne', :action => 'index'
  map.swinburne_poem '/swinburne/:poem_title_id', :controller => 'swinburne', :action => 'poem'
  map.swinburne_poem_page '/swinburne/:poem_title_id/:local_id', :controller => 'swinburne', :action => 'poem_page'
  
  # /swinburne
  # /swinburne/:variant_id
  # /swinburne/:variant_id/:poem_id
  # /swinburne/:variant_id/:poem_id/:page_number
  
  # poem, all variants -- used for comparisons/text-diffs
  # /swinburne/:poem_id
  # /swinburne/:poem_id/:page_number
  
end