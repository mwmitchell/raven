require 'raven'
require 'nokogiri_fragmenter'

class SwinburneMapper
  
  attr_reader :xml_file, :xml, :collection_id
  
  def initialize xml_file
    @xml_file = xml_file
    @xml = Nokogiri::XML open(@xml_file)
    @collection_id = 'swinburne'
  end
  
  def shared_fields
    @shared_fields ||= (
      fname = File.basename(xml_file)
      variant_id = fname.scan(/.*-([A-Z]+)\.xml$/).first.first rescue nil
      {
        :collection_id => collection_id,
        :file_s => xml_file.sub("#{Rails.root}/", ''),
        :filename_s => fname,
        :variant_id => variant_id,
        :collection_title_t => xml.at('//sourceDesc/citnstruct/title').text,
        :author_t => xml.at('//citnstruct/author').text,
        :publisher_t => xml.at('//citnstruct/imprint/publisher').text,
        :printer_t => xml.at('//citnstruct/imprint/printer').text,
        :city_t => xml.at('//citnstruct/imprint/city').text,
        :date_s => xml.at('//citnstruct/imprint/date').text
      }
    )
  end
  
  def map &block
    doc_index = 0
    
    # The teiHeader document...
    yield shared_fields.merge({
      :id => "#{collection_id}-#{doc_index}",
      :parent_id => nil,
      :xml_s => xml.at('teiHeader').to_xml,
      :text => xml.at('teiHeader').text,
      :title => 'Document Information'
    })
    
    doc_index += 1
    
    # indexing the poems/page breaks...
    xml.search('//text').each do |text|
      # create a title for the poem
      poem_title = text['n'].nil? ? 'n/a' : text['n']
      puts "\n** processing new poem... #{poem_title}\n"
      # individual pages broken up by tei pb tags....
      
      parent_id = "#{collection_id}-#{doc_index}"
      
      yield shared_fields.merge({
        :id => parent_id,
        :parent_id => nil,
        :text => text.text,
        :title => poem_title
      })
      
      doc_index += 1
      
      NokogiriFragmenter.fragment(text, 'pb') do |page_fragment|
        pb = page_fragment.at('pb')
        # the page number label
        page_num = pb ? page_fragment.at('pb')['n'].scan(/[0-9]+/).first : 'n/a'
        # the actual page break solr document
        yield shared_fields.merge({
          :id => "#{collection_id}-#{doc_index}",
          :parent_id => parent_id,
          :xml_s => page_fragment.to_xml,
          :text => page_fragment.text,
          :title => page_num
        })
        doc_index += 1
        puts "..."
      end # end fragmenter
    end # end search("//text") (each poem)
  end
  
end