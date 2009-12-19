module SwinburneHelper
  
  def poem_xml_to_html xml
		body = Nokogiri::XML(xml)
		body.traverse do |n|
			css_classes = ["tei", n.name]
			n.keys.each do |k|
				css_classes << k
				css_classes << k + '__' + n[k]
				n.delete k
			end
			n.name = css_classes.include?('quote') ? 'blockquote' : 'div'
			n['class'] = css_classes.join(' ')
		end
		body
	end
  
end