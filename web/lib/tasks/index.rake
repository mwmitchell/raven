def error!(msg)
  puts "
  *** #{msg}
  "
  exit
end

namespace :index do
  
  task :swinburne=>:environment do
    
    require 'raven'
    
    collection_id = 'swinburne'
    
    RSOLR.delete_by_query("collection_id_s:\"#{collection_id}\"")
    RSOLR.commit
    
    Raven.app_dir_contents('collections', collection_id, '*.xml').each do |f|
      next if f =~ /backup/
      
      xml = Nokogiri::XML(open(f))
      fname = File.basename(f)
      variant_id = fname.scan(/.*-([A-Z]+)\.xml$/).first.first rescue nil
      
      shared_fields = {
        :collection_id_s    => collection_id,
        :variant_s          => variant_id,
        :filename_s         => fname,
        :collection_title_s => xml.at('//sourceDesc/citnstruct/title').text,
        :author_s           => xml.at('//citnstruct/author').text,
        :publisher_t        => xml.at('//citnstruct/imprint/publisher').text,
        :printer_t          => xml.at('//citnstruct/imprint/printer').text,
        :city_t             => xml.at('//citnstruct/imprint/city').text,
        :date_s             => xml.at('//citnstruct/imprint/date').text
      }
      
      builder = Raven::NavBuilder::Base.new(collection_id, shared_fields)
      
      root = builder.build(shared_fields[:author_s], variant_id, :first_child=>true) do |root|
        
        root.item 'Document Info', 'info' do |ditem|
          ditem.doc[:xml_s] = xml.at('teiHeader').to_xml
          ditem.doc[:xml_t] = xml.at('teiHeader').text
        end
        
        # swinburne-CW-poems
        root.item 'Poems', 'poems', :first_child=>true do |poems|
          
          # loop through each poem "text" node
          xml.search('//text').each_with_index do |text,poem_index|
            
            poem_title = text['n'].nil? ? 'n/a' : text['n']
            
            puts "
            ** processing a new poem... #{poem_title}
            "
            
            # a poem main navigation-item and document
            # set the label of this nav item to the @n attribute
            poems.item poem_title, poem_index, :first_child=>true do |poem|
              
              page_fragment_index = 0
              
              NokogiriFragmenter.fragment(text, 'pb') do |page_fragment|
                
                puts 'processing a page fragment...'
                
                pb = page_fragment.at('pb')
                
                page_num = pb ? page_fragment.at('pb')['n'].scan(/[0-9]+/).first : 'n/a'
                
                poem.item page_num, page_fragment_index do |poem_page|
                  poem_page.doc.merge!({
                    :title      => text['n'],
                    :title_s    => text['n'],
                    :xml_s      => page_fragment.to_xml,
                    :xml_t      => page_fragment.text
                  })
                end
                
                page_fragment_index += 1
                
              end
              
            end
          end
          #
        end
      end
      
      puts "
      
      ***** processed #{root.documents.size} documents
      
      "
      
      RSOLR.add root.documents
      
      toc_name = [collection_id, variant_id].reject{|i|i.to_s.empty?}.join('.')
      Raven::DocExt::TOC.store_toc(root.navigation, toc_name)
      
    end
    
    RSOLR.commit
    
  end
  
end