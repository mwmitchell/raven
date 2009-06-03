require 'raven'

def error!(msg)
  puts "
  *** #{msg}
  "
  exit
end

namespace :index do
  
  task :swinburne=>:environment do
    #RSOLR.delete_by_query("collection_id_s:\"#{swinburne}\"")
    #RSOLR.commit
    Raven.app_dir_contents('collections', 'swinburne', 'source', '*.xml').each do |f|
      xml = Nokogiri::XML(open(f))
      fname = File.basename(f)
      copy_id = fname.scan(/.*-(.*)\.xml$/).first.first rescue ''
      indexer = Raven::Indexers::TEI.new(xml)
      indexer.build do |doc|
        id                    = "#{fname.gsub(/^tei-|\.xml$/,'')}-#{doc[:id]}"
        doc[:id]              = id
        doc[:copy_s]          = copy_id
        doc[:filename_s]      = fname
        doc[:collection_id_s] = 'swinburne'
      end
      #RSOLR.add indexer.solr_docs
      #store_toc indexer.toc, copy_id
    end
  end
  
end