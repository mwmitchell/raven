require 'java'
require "lib/saxonb9-1-0-6j/saxon9.jar"

module Saxon
  
  def self.transform(stylesheet_file, source_file, output_file, params={})
    #import javax.xml.transform.TransformerFactory
    #import javax.xml.transform.stream.StreamSource
    #import javax.xml.transform.stream.StreamResult
    
    tfactory = javax.xml.transform.TransformerFactory.newInstance
    
    params.each_pair {|k,v|tfactory.setAttribute(k,v)}
    transformer = tfactory.newTransformer(
      javax.xml.transform.stream.StreamSource.new(stylesheet_file)
    )

    transformer.transform(
      javax.xml.transform.stream.StreamSource.new(source_file),
      javax.xml.transform.stream.StreamResult.new(output_file)
    )
  end
  
end