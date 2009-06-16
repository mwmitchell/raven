namespace :index do
  
  task :swinburne=>:environment do
    
    def collection_id; 'swinburne' end
    def generate_id(*args); ([collection_id] + args).join('-') end
    
    require 'raven'
    
    solr_docs = []
    
    Raven.app_dir_contents('collections', collection_id, '*.xml').each do |f|
      # skip the backup file
      next if f =~ /backup/
      puts "\n\t** file: #{f}\n"
      # create the xml object
      xml = Nokogiri::XML open(f)
      # grab the basename from the file
      fname = File.basename f
      # create the variant_id (the book "copy") from the fname
      variant_id = fname.scan(/.*-([A-Z]+)\.xml$/).first.first rescue nil
      #
      #
      # A base solr doc that all solr docs "inherit" from
      base_solr_doc = {
        :collection_base_s => 'swinburne',
        :collection_id_s    => [collection_id, variant_id].compact.join('-'),
        :filename_s         => fname,
        :variant_s          => (variant_id || 'Original'),
        :variant_id_s       => variant_id,
        :collection_title_s => xml.at('//sourceDesc/citnstruct/title').text,
        :author_s           => xml.at('//citnstruct/author').text,
        :publisher_t        => xml.at('//citnstruct/imprint/publisher').text,
        :printer_t          => xml.at('//citnstruct/imprint/printer').text,
        :city_t             => xml.at('//citnstruct/imprint/city').text,
        :date_s             => xml.at('//citnstruct/imprint/date').text
      }
      #
      #
      # The teiHeader document...
      solr_docs << base_solr_doc.merge({
        :id => generate_id(solr_docs.size),
        :xml_s => xml.at('teiHeader').to_xml,
        :xml_t => xml.at('teiHeader').text,
        :title => 'Document Info',
        :path_s => 'Document Info',
        :position_i => 0
      })
      
      # indexing the poems/page breaks...
      xml.search('//text').each do |text|
        # create a title for the poem
        poem_title = text['n'].nil? ? 'n/a' : text['n']
        puts "\n** processing new poem... #{poem_title}\n"
        # individual pages broken up by tei pb tags....
        i = -1
        NokogiriFragmenter.fragment(text, 'pb') do |page_fragment|
          i += 1
          pb = page_fragment.at('pb')
          # the page number label
          page_num = pb ? page_fragment.at('pb')['n'].scan(/[0-9]+/).first : 'n/a'
          # the actual page break solr document
          solr_docs << base_solr_doc.merge({
            :id => generate_id(solr_docs.size),
            :xml_s => page_fragment.to_xml,
            :xml_t => page_fragment.text,
            :title => poem_title,
            :title_s => poem_title,
            :path_s => "Poems::#{poem_title}::#{page_num}",
            :position_i => i
          })
          puts "..."
        end # end fragmenter
      end # end search("//text") (each poem)
      
    end # end files loop
    
    Raven.solr.delete_by_query("collection_base_s:#{collection_id}*")
    Raven.solr.add solr_docs
    Raven.solr.commit
    
  end
  
end