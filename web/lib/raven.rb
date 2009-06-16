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
  
end