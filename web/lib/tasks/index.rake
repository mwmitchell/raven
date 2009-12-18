namespace :index do
  
  task :swinburne=>:environment do
    Raven.app_dir_contents('collections', collection_id, '*.xml').each do |f|
      # skip the backup file
      next if f =~ /backup/
      puts "\n\t** file: #{f}\n"
      mapper = SwinburneMapper.new f
      mapper.map do |solr_doc|
        
      end
    end
    #Raven.solr.delete_by_query("collection_base_s:#{collection_id}*")
    #Raven.solr.add solr_docs
    #Raven.solr.commit
  end
  
end