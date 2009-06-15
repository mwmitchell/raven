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
        b.extend Raven::Navigation::Navigational
        b.navigation_name = b[:collection_id_s]
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
  
  
  #######################
  
  #
  # navigation builder
  #
  module Navigation
    
    # ActiveSupport::JSON doesn't like embedded quotes
    # the JSON gem doesn't mind...
    require 'json'
    
    mattr_accessor :base_dir
    @base_dir = Raven.app_path('tmp', 'cache', 'nav')
    
    def self.dump(nav, name)
      raise "Navigation object can only be a Hash" unless nav.class==Hash
      file = File.join(self.base_dir, "#{name}.json")
      File.open(file, File::CREAT|File::TRUNC|File::WRONLY) do |f|
        f.puts nav.to_json
      end
    end
    
    # Loads a json based navigation file,
    # and converts into a Ruby hash object.
    # The Flatten and Contextual modules are mixed in.
    def self.load(name)
      json_nav = File.read(File.join(self.base_dir, "#{name}.json"))
      hash = ::JSON.parse(json_nav)
      hash.extend Raven::Navigation::NodeMethods
      hash
    end
    
    module NodeMethods
      
      def self.extended(b)
        b.extend Contextual
        b.extend Flatten
      end
      
      module Contextual
        def self.extended(b)
          b['children'].each do |child|
            child.extend Contextual
            child.parent = b
          end
        end
        def parent=(p)
          @parent = parent
        end
        def parent
          @parent
        end
      end
    
      module Flatten
      
        def self.extended(b)
          b['children'].each{|child| child.extend Flatten }
        end
      
        def flatten
          [self] + self['children'].map{|child| child.flatten }.flatten
        end
      
      end
    
    end
    
    # used to enhance a Hash object with navigation methods.
    # The Hash must have an :id key
    module Navigational
      
      def navigation_name=(n)
        @navigation_name = n
      end
      
      def navigation_name
        @navigation_name
      end
      
      # collects all nodes that have children with the same id as this doc
      # returns the last one
      def target_nav
        @target_nav ||= (
          self.full_nav.flatten.select{|d|d['children'].any?{|c|c['id'] == self[:id]}}.last
        )
      end
      
      def full_nav
        @full_nav ||= (
          Raven::Navigation.load(self.navigation_name)
        )
      end
      
      def to_html(nav)
        html += '<ul>'
        html += '<li>' + nav['label']
        unless nav['children'].empty?
          nav['children'].each do |child|
            html += to_html(child)
          end
        end
        html += '</li>'
        html += '</ul>'
      end
      
    end
    
    #############################################################################
    
    #
    # Helper module for building and exporting hierarchical navigation structures
    #
    module Builder
      
      def self.build(label, opts={}, &blk)
        root = Item.new(label, opts)
        yield root
        root
      end
      
      # used for creating a navigation hierarchy,
      # then exporting to a simple array/hash format.
      class Item
        
        attr_reader :label, :opts, :parent
        
        def initialize(label, opts={}, parent=nil)
          @label = label
          @opts = opts
          if parent
            @parent = parent
            parent.children << self
          end
        end
        
        def flatten
          [self] + self.children.map{|child| child.flatten}.flatten
        end
        
        def children
          @children ||= []
        end
        
        def item(label, opts={}, &blk)
          item = self.class.new(label, opts, self)
          yield item if block_given?
          item
        end
        
        # exports a simple hash/array tree
        # the :id value is incremented from 0
        # the :label value is copied from self.label
        # the :children value is always an array, could be empty.
        # each item is yielded AFTER its children have been built.
        def export(i=0, &blk)
          item_hash = {
            :id => i,
            :label => self.label,
            :children => self.children.map{|child| child.export(i+1, &blk) }
          }
          yield item_hash if block_given?
          item_hash
        end
        
      end
      
    end
    
  end
  
end