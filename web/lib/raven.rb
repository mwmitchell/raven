module Raven
  
  def self.app_path(*items)
    File.join(RAILS_ROOT, *items)
  end
  
  def self.app_dir_contents(*items)
    Dir[app_path(*items)]
  end
  
  module DocExt
    
    TOC_BASE_DIR = Raven.app_path('tmp', 'cache', 'toc')
    
    module TOC

      def target_toc
        @target_toc ||= (
          full_toc.detect{|i| i['children'].detect{|cc|cc['id'] == self[:id]} }
        )
      end
      
      def full_toc
        @full_toc ||= (
          toc_file = "toc#{self[:copy_s].nil? ? '' : '.' + self[:copy_s]}.json"
          ActiveSupport::JSON.decode(File.read(TOC_BASE_DIR + "/#{self[:collection_id_s]}/#{toc_file}"))
        )
      end
      
      def self.store_toc(toc, unit_id)
        file = app_path('tmp', 'cache', 'toc', unit_id)
        file += ".#{unit_id}" unless unit_id.empty?
        file += ".json"
        File.open(file, File::CREAT|File::TRUNC|File::WRONLY) do |f|
          f.puts toc.to_json
        end
      end
      
    end
    
  end
  
  #
  module Indexers
    
    #
    class TEI
      
      attr_reader :solr_docs, :toc
      
      def initialize(xml)
        require 'nokogiri_fragmenter'
        @xml = xml
        @solr_docs = []
        @toc = []
      end
      
      def build(base_solr_doc={}, &blk)
        base = auto_base_solr_doc.merge(base_solr_doc)
        build_solr_doc(base) do |doc|
          yield doc
          @solr_docs << doc
        end
      end
      
      def build_solr_doc(base_solr_doc)
        NokogiriFragmenter.fragment(@xml, 'pb').each_with_index do |chunk,index|
          puts "chunk"
          exit
        end
      end
      
      #
=begin
      def build_solr_doc(base_solr_doc)
        @xml.search('//text').each_with_index do |text,index|
          @toc << {:label=>text['n'], :id=>nil, :children=>[]}
          NokogiriFragmenter.fragment(text.to_xml, 'pb').each_with_index do |chunk,index2|
            solr_doc = base_solr_doc.dup
            solr_doc.merge!({
              :id         => ("#{index}-#{index2}"),
              :title      => text['n'],
              :title_s    => text['n'],
              :xml_s      => chunk.to_xml,
              :xml_t      => chunk.text
            })
            # make the parent toc item link to the first child
            @toc.last[:id] ||= solr_doc[:id]
            page_num = chunk.at('pb')['n'].scan(/[0-9]+/).first
            @toc.last[:children] << {:label=>page_num, :id=>solr_doc[:id], :children=>[]}
            # add the doc
            yield solr_doc
            puts 'Processing next page break...'
          end
        end
      end
=end
      
      def auto_base_solr_doc
        {
          :collection_title_s => @xml.at('//sourceDesc/citnstruct/title').text,
          :author_s           => @xml.at('//citnstruct/author').text,
          :publisher_t        => @xml.at('//citnstruct/imprint/publisher').text,
          :printer_t          => @xml.at('//citnstruct/imprint/printer').text,
          :city_t             => @xml.at('//citnstruct/imprint/city').text,
          :date_s             => @xml.at('//citnstruct/imprint/date').text
        }
      end
      
    end
    
  end
  
end