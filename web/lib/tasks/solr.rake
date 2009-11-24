namespace :solr do
  
  task :start do
    `cd ../solr && java -Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl -jar start.jar`
  end
  
end