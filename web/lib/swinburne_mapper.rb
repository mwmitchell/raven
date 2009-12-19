require 'raven'
require 'nokogiri_fragmenter'
require 'string_ext'

class SwinburneMapper
  
  attr_reader :xml_file, :xml, :collection_id, :variant_id
  
  def initialize xml_file
    @xml_file = xml_file
    @xml = Nokogiri::XML open(@xml_file)
    @collection_id = 'swinburne'
    @variant_id = xml_file.scan(/.*-([A-Z]+)\.xml$/).first.first.downcase rescue 'original'
  end
  
  def shared_fields
    @shared_fields ||= (
      fname = File.basename(xml_file)
      {
        :collection_id => collection_id,
        :file_s => xml_file.sub("#{Rails.root}/", ''),
        :filename_s => fname,
        :variant_facet => variant_id,
        :collapse_id => "#{collection_id}-#{variant_id}",
        :collection_title_t => xml.at('//sourceDesc/citnstruct/title').text,
        :author_t => xml.at('//citnstruct/author').text,
        :publisher_t => xml.at('//citnstruct/imprint/publisher').text,
        :printer_t => xml.at('//citnstruct/imprint/printer').text,
        :city_t => xml.at('//citnstruct/imprint/city').text,
        :date_s => xml.at('//citnstruct/imprint/date').text,
        :physical_cover_t => xml.at('//binding/cover').text,
        :provenance_location_t => xml.at('//provenance/location').text,
        :provenance_recnum_t => xml.at('//provenance/recnum').text,
      }
    )
  end
  
  def map &block
    doc_index = 0
    
    # indexing the poems/page breaks...
    xml.search('//text').each do |text|
      # create a title for the poem
      poem_title = text['n'].nil? ? 'n/a' : text['n']
      puts "\n** processing new poem... #{poem_title}\n"
      # individual pages broken up by tei pb tags....
      
      NokogiriFragmenter.fragment(text, 'pb') do |page_fragment|
        
        pb = page_fragment.at('pb')
        
        # skip pages that have no content
        if pb.parent.children.all?{|n| n.text? or n.name=='pb' }
          puts "Skipping page (#{pb.inspect}) with no content"
          next
        end
        
        # the page number label
        page_num = pb ? page_fragment.at('pb')['n'].scan(/[0-9]+/).first : 'n/a'
        # the actual page break solr document
        local_id = "#{variant_id}-#{doc_index}"
        yield shared_fields.merge({
          :id => "#{collection_id}-#{local_id}",
          :local_id => local_id,
          :xml_s => page_fragment.to_xml,
          :xml_t => page_fragment.text,
          :text => page_fragment.text,
          :poem_title_t => poem_title,
          :poem_title_facet => poem_title,
          :poem_slug_s => poem_title.to_slug,
          :title => "#{poem_title}, Page #{page_num}",
          :page_s => page_num,
        })
        doc_index += 1
        puts "..."
      end # end fragmenter
    end # end search("//text") (each poem)
  end
  
end