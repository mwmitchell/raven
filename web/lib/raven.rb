module Raven
  
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
      
      NAV_BASE_DIR = Raven.app_path('tmp', 'cache', 'nav')
      
      def self.extended(b)
        b.extend Nav
      end
      
      module Nav
        
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
        
        # ActiveSupport::JSON doesn't like embedded quotes
        # the JSON gem doesn't mind...
        require 'json'
        
        module Flatten
          
          def self.extended(b)
            b['children'].each{|child| child.extend Flatten }
          end
          
          def flatten
            [self] + self['children'].map{|child| child.flatten }.flatten
          end
          
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
            nav_file = self[:variant_s].to_s.empty? ? '' : '.' + self[:variant_s]
            json_nav = File.read(NAV_BASE_DIR + "/#{self[:collection_id_s]}#{nav_file}.json")
            hash = ::JSON.parse(json_nav)
            hash.extend Flatten
            hash.extend Contextual
            hash
          )
        end
        
        #def self.to_html(nav)
        #  html += '<ul>'
        #  html += '<li>' + nav['label']
        #  unless nav['children'].empty?
        #    nav['children'].each do |child|
        #      html += to_html(child)
        #    end
        #  end
        #  html += '</li>'
        #  html += '</ul>'
        #end
        
        def self.store!(nav, name)
          file = File.join(NAV_BASE_DIR, name)
          file += ".json"
          File.open(file, File::CREAT|File::TRUNC|File::WRONLY) do |f|
            f.puts nav.to_json
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
  
  # ==NavBuilder is a class specifically designed to 
  # create a simple tree, and an associated flat list of hash documents.
  # each tree node has an id, label and children
  # each document must have an :id key
  # 
  # The tree/navigation nodes can be linked to their own document,
  # or to its first child document by using the :first_child=>true option
  # 
  # ===Example:
  #
  #   b = NavBuilder::Base.new('base-id')
  #   root = b.build 'Collection', 'collection', :first_child=>true do |citem|
  #     citem.doc[:text] = 'woot!'
  #   end
  #   root.documents
  #   root.navigation
  #
  # ===Output:
  # When the #navigation method is called on the result object,
  # a "root" hash is returned.
  # When the #documents method is called.
  # an array is returned with all documents, except the root
  # The id's of the tree nodes and documents are
  # synchronized at export time.
  module NavBuilder

    # The Item class represents a document (hash)
    # and a node in the navigation hierarchy.
    class Item

      # "label" is the "UI" label for the node in the navigation tree
      # "doc" is the hash document that is included in the #documents array
      attr_reader :label, :doc, :opts
      
      # "key" single fragment identifier for this node
      attr_accessor :key
      
      # the absolute unique id of this node in context of the entire tree
      attr_accessor :id
      
      # "base" is a NavBuilder::Base object
      attr :base
      # "parent" is an Item object
      attr :parent
      # "children" is an array of Item objects
      attr :children
      
      # "base" is an instance of NavBuilder::Base
      # "label" is a string to represent this node in the tree
      # "key" is a value used to reprent this item and its document
      # "opts" is a hash -- :first_child (boolean) is the only valid key
      # "parent" is an optional instance of Item
      def initialize(base, label, key, opts={}, parent=nil)
        @base = base
        @label = label
        @key = key
        @opts = opts
        @doc = @base.base_doc.dup unless opts[:first_child]
        @parent = parent
        @children = []
        @id = generate_id
      end
      
      # creates a child node
      # yields the child instance
      # returns the child instance
      def item(label, key, opts={})
        i = self.class.new(self.base, label, key, opts, self)
        @children << i
        yield i if (block_given? or opts[:first_child]) # will raise error if first_child and no block present
        i
      end
      
      # returns a simple hash tree
      # the :id key is set to the value of absolute_id OR
      # the value of the first child if the :first_child option is true
      def navigation
        {
          :label => self.label,
          :id => self.absolute_id,
          :children => self.children.map{|child| child.navigation}
        }
      end
      
      # returns the full id with the self.base.name prepended
      def absolute_id
        [self.base.name, self.id].join('-')
      end
      
      # returns an array of hash documents
      def documents
        d = self.doc.dup
        d[:id] = self.absolute_id
        ([d] + self.children.map{|child| child.documents }.flatten).compact
      end
      
      protected

      # called when the #navigation and/or #documents method is called
      # builds a hierarchical id string using:
      #   parent.generate_id
      #   self.key
      # the values are joined by a -
      def generate_id
        items = []
        items << self.parent.generate_id unless self.parent.nil?
        items << self.key
        items.join('-')
      end
      
    end
    
    class Base
      
      # "name" is the base id value for documents and tree nodes
      # "base_doc" is a hash that serves as the shared data for all documents
      # "root" is the root node, instance of Item
      attr_reader :name, :base_doc, :root

      def initialize(name, base_doc={}, &blk)
        @name = name
        @base_doc = base_doc
      end
      
      # yields the "root" Item instance
      def build(label, key, opts={}, &blk)
        @root = Item.new(self, label, key, opts)
        yield @root
        @root
      end

    end

  end
  
  #######################
  
  #
  # simplified navigation builder
  #
  module Navigation

    module Build

      class Item

        attr :builder
        attr_reader :id, :opts, :parent

        def initialize(builder, id, opts={}, parent=nil, &blk)
          @builder = builder
          @id = id
          @opts = opts
          if parent
            @parent = parent
            parent.children << self
          end
        end

        def children
          @children ||= []
        end

        def item(*args, &blk)
          # create an id based on the size of the "items" array
          args.unshift(builder.items.size) if args.size == 0 || args.first.class==Hash
          # push on the opts hash if it's not present
          args << {} if args.last.class != Hash
          # add the parent (self)
          args << self
          # unshift the self.builder instance as the first argument
          args.unshift self.builder
          # push the item on to the builder's items list
          self.builder.items << self.class.new(*args)
          # yield!
          yield self.builder.items.last if block_given?
          # make sure the id is globally uniqe
          ids = self.builder.ids
          raise "ID (#{self.id}) is not unique!" if ids != ids.uniq
        end

        # exports a simple hash/array tree
        def export
          {
            :id => self.id,
            :opts => self.opts,
            :children => self.children.map{|child| child.export }
          }
        end

      end

      class R

        def items
          @items ||= []
        end

        def build(opts={}, &blk)
          root = Item.new(self, nil, opts, nil)
          yield root
          root
        end
        
        def ids
          self.items.map{|i|i.id}
        end
        
      end
      
    end
    
  end
  
end