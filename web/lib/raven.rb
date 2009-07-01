require 'rubygems'
require 'activesupport'

module Raven
  
  # solr access method...
  # Example:
  # Raven.solr.find(:q=>'*:*')
  def self.solr
    @solr ||= (
      c = RSolr::Ext.connect
      c.adapter.connector.adapter_name = :net_http
      c.extend SolrExt::Connection
    )
  end
  
  def self.app_path(*items)
    File.join(RAILS_ROOT, *items)
  end
  
  def self.app_dir_contents(*items)
    Dir[app_path(*items)]
  end
  
  module SolrExt
    
    module Doc
      
      def self.extended(b)
        b.extend Navigational
      end
      
      module Navigational
        
        def navigation
          if self[:collection_id_s]
            @navigation ||= (
              # using :phrases (quoted q values) and standard query parser...
              # is much faster than an fq and dismax parser... don't know why.
              nav_response = Raven.solr.find({
                :phrases=>{:collection_id_s => self[:collection_id_s]},
                :fl => 'id,path_s',
                :rows => 100000,
                :sort => 'position_i asc'
              })
              Raven::MaterializedPath.to_composite(nav_response.docs) do |doc|
                doc[:path_s].split('::')
              end
            )
          end
        end
        
        def target_navigation
          if n = self.navigation
            @target_navigation ||= (
              n.descendants.detect{|d|d.object and d.object[:id]==self[:id]}.parent rescue nil
            )
          end
        end
        
      end
      
    end
    
    module Connection
      def find(*args, &blk)
        r = super(*args, &blk)
        r.docs.each{|d|d.extend Doc}
        r
      end
    end
    
  end
  
  module MaterializedPath
    
    # Translates an array of objects into composite hierarchy.
    # Each item in the array should have some kind of path value: a/b/c/d/e
    # Must provide a block, that returns an array of path values:
    # root = MaterializedPath.to_composite(array_of_items_with_paths) do |item|
    #   item[:path].split('/')
    # end
    # root.children
    # root.descendants
    # root.object # the original item in the array
    def self.to_composite(set, opts={})
      root = Composite.new('root')
      # loop through each object in the array
      set.each do |item|
        path_fragments = yield(item)
        composite = nil # define in outer scope to set the :item
        path_fragments.inject(root) do |composite,fragment|
          composite.children.detect{|child|child.value==fragment} or Composite.new(fragment, composite)
        end
        # the last path item is always the object
        composite.children.last.object = item
      end
      root
    end
    
    # A class that represents a tree/hierarchical-node
    class Composite
      
      attr_reader :value, :parent
      attr_accessor :object
      
      def initialize(value='', parent=nil)
        @value, @parent = value, parent
        parent.children << self if parent
      end
      
      def children
        @children ||= []
      end
      
      def descendants
        self.children.map{|c|c.children + c.descendants}.flatten
      end
      
      def ancestors
        (self.parent and self.parent.parent) ? ([self.parent.parent] + self.parent.ancestors) : []
      end
      
      def siblings
        self.parent ? (self.parent.children - [self]) : []
      end
      
    end
    
  end
  
end