namespace :index do
  
  task :swinburne=>:environment do
    Raven.solr.delete_by_query("*:*")
    Raven.app_dir_contents('collections', 'swinburne', '*.xml').each do |f|
      # skip the backup file
      next if f =~ /backup/
      puts "\n\t** file: #{f}\n"
      mapper = SwinburneMapper.new f
      mapper.map do |solr_doc|
        puts solr_doc[:id]
        Raven.solr.add solr_doc
      end
    end
    Raven.solr.commit
  end
  
end