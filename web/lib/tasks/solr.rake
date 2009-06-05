namespace :solr do
  
  task :start do
    `cd ../solr && java -jar start.jar`
  end
  
end