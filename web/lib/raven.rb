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
              nav_response = Raven.solr.find({
                :phrases=>{:collection_id_s => self[:collection_id_s]},
                :fl => 'id,path_s',
                :rows => 100000,
                :sort => 'position_i asc'
              })
              Raven::MaterializedPath.set_to_composite(nav_response.docs, :field=>:path_s)
            )
          end
        end
        
        def target_navigation
          if n = self.navigation
            @target_navigation ||= (
              n.descendants.detect{|d|d.object and d.object[:id]==self[:id]}.parent
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
    
    def self.set_to_composite(set, opts={})
      unless block_given?
        opts[:delimiter]  ||= '::'
        opts[:field]      ||= :path
      end
      root = Composite.new('root')
      set.each do |item|
        val = block_given? ? yield(item) : item[opts[:field]].to_s.split(opts[:delimiter])
        acc = nil # define in outer scope to set the :item
        val.compact.inject(root) do |acc,k|
          acc.children << Composite.new(k, acc) unless acc.children.any?{|i|i.label==k}
          acc.children.detect{|i|i.label==k}
        end
        # the last path item is always the object
        acc.children.last.object = item
      end
      root
    end
    
    class Composite
      
      attr_reader :label, :parent
      attr_accessor :object
      
      def initialize(label='', parent=nil)
        @label, @parent = label, parent
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