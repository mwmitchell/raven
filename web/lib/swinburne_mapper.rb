require 'raven'
require 'nokogiri_fragmenter'

# string_ext brings in the to_slug method for strings
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
        # the string id of the entire swinburne collection... represents all poems, all variants, all pages etc..
        :collection_id => collection_id,
        # the file path where this info came from
        :file_s => xml_file.sub("#{Rails.root}/", ''),
        # the file-name
        :filename_s => fname,
        # the variant (better name?) which currently comes from the file name
        :variant_s => variant_id,
        # used to tie similar results together -- a source file's contents should be grouped together using this
        :collapse_id => "#{collection_id}-#{variant_id}",
        # the friendly title of this collection
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
      
      poem_id = poem_title.to_slug
      
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
        
        # the TEI page-break solr document id
        local_id = "#{variant_id}-#{doc_index}"
        
        yield shared_fields.merge({
          # absolute id, unique to ever solr document
          :id => "#{collection_id}-#{local_id}",
          # a short, unique id, local to this collection's poem
          :local_id => local_id,
          # used for displaying/transforming the raw xml
          :xml_s => page_fragment.to_xml,
          
          # raw xml within text field -- seems to work well forsource highlighting?
          :xml_source_t => page_fragment.to_xml,
          
          # the xml *text only*, used for highlighing and searching
          :xml_t => page_fragment.text,
          # push the xml text into the main "text" field for easy searching
          :text => page_fragment.text,
          # the poem title, stored as a facet
          :poem_title_s => poem_title,
          # the poem title, transformed into a url friendly value
          :poem_title_id => poem_id,
          # this solr document title
          :title => "#{poem_title}, p. #{page_num}",
          # the page number of this poem fragment
          :page_number_s => page_num,
        })
        doc_index += 1
        puts "..."
      end # end fragmenter
    end # end search("//text") (each poem)
  end
  
end