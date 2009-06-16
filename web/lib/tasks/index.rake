namespace :index do
  
  task :swinburne=>:environment do
    
    def collection_id; 'swinburne' end
    
    require 'raven'
    
    solr_docs = []
    nav_items = {}
    
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
        :collection_id_s    => [collection_id, variant_id].compact.join('-'),
        :filename_s         => fname,
        :variant_s          => variant_id,
        :collection_title_s => xml.at('//sourceDesc/citnstruct/title').text,
        :author_s           => xml.at('//citnstruct/author').text,
        :publisher_t        => xml.at('//citnstruct/imprint/publisher').text,
        :printer_t          => xml.at('//citnstruct/imprint/printer').text,
        :city_t             => xml.at('//citnstruct/imprint/city').text,
        :date_s             => xml.at('//citnstruct/imprint/date').text
      }
      #
      #
      #
      # The following section basically builds a navigation structure
      # and associates the solr docs to each of the nodes in the navigation
      # hierarchy. The navigation (hash/arrays) is stored as json,
      # and later rendered into the web app, at which point it has
      # access to all of the associated solr doc ids.
      root_label = "#{base_solr_doc[:collection_title_s]} by #{base_solr_doc[:author_s]}"
      # The navigation builder instance
      navigation_builder = Raven::Navigation::Builder.new(:prefix=>base_solr_doc[:collection_id_s])
      # The root navigation node (display title and author)
      navigation_builder.build(root_label) do |root_nav|
        # creeate a document info navigation node... (teiHeader)
        root_nav.item 'Document Info' do |doc_nav|
          solr_docs << base_solr_doc.merge({
            :id => doc_nav.id,
            :xml_s => xml.at('teiHeader').to_xml,
            :xml_t => xml.at('teiHeader').text
          })
        end
        # all poems...
        root_nav.item 'Poems' do |poems_nav|
          # find each "text" element
          xml.search('//text').each do |text|
            # create a title for the poem
            poem_title = text['n'].nil? ? 'n/a' : text['n']
            puts "\n** processing new poem... #{poem_title}\n"
            # create a poem navigation node...
            poems_nav.item poem_title do |poem_nav|
              # individual pages broken up by tei pb tags....
              NokogiriFragmenter.fragment(text, 'pb') do |page_fragment|
                pb = page_fragment.at('pb')
                # the page number label
                page_num = pb ? page_fragment.at('pb')['n'].scan(/[0-9]+/).first : 'n/a'
                # the page break navigation element...
                poem_nav.item page_num do |poem_item_nav|
                  # the actual page break solr document
                  solr_docs << base_solr_doc.merge({
                    :id => poem_item_nav.id,
                    :xml_s => page_fragment.to_xml,
                    :xml_t => page_fragment.text
                  })
                end
                puts "..."
              end # end fragmenter
            end # and poem nav item
          end # end search("//text") (each poem)
        end # end poems nav
      end # end Builder.build
      
      # store the navigation data for this file, in the nav_items hash...
      nav_items[base_solr_doc[:collection_id_s]] = navigation_builder.export
      
    end # end files loop
    
    # store the json navigation data for each file indexed...
    nav_items.each {|k,v| Raven::Navigation.dump(v, k) }
    
    Raven.solr.delete_by_query("collection_id_s:#{collection_id}*")
    Raven.solr.add solr_docs
    Raven.solr.commit
    
  end
  
end