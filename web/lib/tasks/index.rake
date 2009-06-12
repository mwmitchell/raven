namespace :index do
  
  task :swinburne=>:environment do
    
    solr = Raven.solr
    
    stime = Time.now
    
    require 'raven'
    
    def collection_id
      'swinburne'
    end
    
    def generate_id(*args)
      ([collection_id] + args).reject{|v|v.to_s.empty?}.join('-')
    end
    
    solr_docs = []
    
    solr.delete_by_query("collection_id_s:#{collection_id}*")
    solr.commit
    
    Raven.app_dir_contents('collections', collection_id, '*.xml').each do |f|
      next if f =~ /backup/
      
      xml = Nokogiri::XML(open(f))
      fname = File.basename(f)
      
      variant_id = fname.scan(/.*-([A-Z]+)\.xml$/).first.first rescue nil
      
      base_solr_doc = {
        :collection_id_s    => [collection_id, variant_id].compact.join('-'),
        :filename_s         => fname,
        :collection_title_s => xml.at('//sourceDesc/citnstruct/title').text,
        :author_s           => xml.at('//citnstruct/author').text,
        :publisher_t        => xml.at('//citnstruct/imprint/publisher').text,
        :printer_t          => xml.at('//citnstruct/imprint/printer').text,
        :city_t             => xml.at('//citnstruct/imprint/city').text,
        :date_s             => xml.at('//citnstruct/imprint/date').text
      }
      
      navigation = Raven::Navigation::Build::R.new
      
      root = navigation.build do |root_nav|
        
        root_nav.opts[:label] = "#{base_solr_doc[:collection_title_s]} by #{base_solr_doc[:author_s]}"
        
        root_nav.item :label=>'Document Info' do |doc_info_nav|
          info_solr_doc = base_solr_doc.dup
          info_solr_doc[:id] = generate_id(variant_id, doc_info_nav.id)
          info_solr_doc[:xml_s] = xml.at('teiHeader').to_xml
          info_solr_doc[:xml_t] = xml.at('teiHeader').text
          solr_docs << info_solr_doc
          doc_info_nav.opts[:solr_id] = info_solr_doc[:id]
        end
        
        # swinburne-CW-poems
        root_nav.item :label=>'Poems' do |poems_nav|
          
          # loop through each poem "text" node
          xml.search('//text').each_with_index do |text,poem_index|
            
            poem_title = text['n'].nil? ? 'n/a' : text['n']
            
            puts "
            ** processing a new poem... #{poem_title}
            "
            
            poems_nav.item :label=>poem_title do |poem_nav|
              
              NokogiriFragmenter.fragment(text, 'pb') do |page_fragment|
                
                puts 'processing a page fragment...'
                
                pb = page_fragment.at('pb')
                
                # the page number label
                page_num = pb ? page_fragment.at('pb')['n'].scan(/[0-9]+/).first : 'n/a'
                
                poem_nav.item :label=>page_num do |poem_page_nav|
                  poem_page_solr_doc = base_solr_doc.dup.merge({
                    :title      => text['n'],
                    :title_s    => text['n'],
                    :xml_s      => page_fragment.to_xml,
                    :xml_t      => page_fragment.text
                  })
                  poem_page_solr_doc[:id] = generate_id(variant_id, poem_page_nav.id)
                  solr_docs << poem_page_solr_doc
                  poem_page_nav.opts[:solr_id] = poem_page_solr_doc[:id]
                end
                
              end
              
            end
          end
          #
        end
        
      end
      
      puts "
      
      *****
      ***** processed #{solr_docs.size} documents in #{Time.now - stime}
      *****
      
      "
      
      nav_name = [collection_id, variant_id].reject{|i|i.to_s.empty?}.join('.')
      Raven::SolrExt::Doc::Nav.store!(root.export, nav_name)
      
    end
    
    solr.add solr_docs
    solr.commit
    
    puts "total index time: #{Time.now - stime}"
    
  end
  
end