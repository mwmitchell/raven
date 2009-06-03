module DocumentsHelper
  
  include WillPaginate::ViewHelpers
  
  def add_facet_params(field, value)
    p = params.dup
    p.delete :page
    p[:f]||={}
    p[:f][field] ||= []
    p[:f][field].push(value)
    p
  end

  def remove_facet_params(field, value)
    p=params.dup
    p.delete :page
    p[:f][field] = p[:f][field] - [value]
    p
  end
  
  def facet_in_params?(field, value)
    params[:f] and params[:f][field] and params[:f][field].include?(value)
  end
  
  # add highlighting to RSolr::Ext?
  def hl_snippets(doc, opts = {:max=>5})
    max_snippets = 0
    return unless @response[:highlighting]
    @response[:highlighting][doc[:id]].each_pair do |field, value|
      break if max_snippets > opts[:max]
      max_snippets += 1
      yield field,value
    end
  end
  
  # performs an XSLT transform
  def xslt(stylesheet_file_path, document, params={})
    document = Nokogiri::XML(document) if document.is_a?(String)
    stylesheet = Nokogiri::XSLT.parse(render(stylesheet_file_path))
    stylesheet.apply_to(Nokogiri::XML(document.to_xml), params)
  end
  
  def build_toc(toc, opts={})
    html = '<ul class="toc">'
    toc.each do |item|
      label = item['label'].blank? ? '[no title]' : item['label']
      html << "<li>#{link_to_unless_current(label, document_path(item['id']))}"
      if opts[:recurse] and (item['id'] == params[:id] || (item['children'] and item['children'].any?{|c|c['id']==params[:id]} )) and item['children'].size > 0
        html << "<ul>"
        item['children'].each do |n|
          html << "<li>#{link_to_unless_current(n['label'], document_path(n['id']))}</li>"
        end
        html << "</ul>"
      end
      html << "</li>"
    end
    html + '</ul>'
  end
  
end