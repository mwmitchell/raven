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
  
  # performs an XSL transform
  def xslt(stylesheet_file_path, document, params={})
    document = Nokogiri::XML(document) if document.is_a?(String)
    stylesheet = Nokogiri::XSLT render(stylesheet_file_path)
    stylesheet.transform document, params.inject([]){|accumulator,(k,v)|accumulator += [k.to_s,v.to_s]}
  end
  
=begin
  def xslt(style, doc, params={})
    path_to_saxon_jar = File.join(RAILS_ROOT, 'lib', 'saxonb9-1-0-6j', 'saxon9.jar')
    name = Time.now.to_i
    docf = "/tmp/cache/doc_fragments/#{name}.xml"
    FileUtils.mkdir_p(File.dirname(docf))
    File.open(docf, File::WRONLY|File::TRUNC|File::CREAT) do |f|
      f.puts doc.to_s
    end
    stylef = "/tmp/cache/doc_styles/#{name}.xsl"
    FileUtils.mkdir_p(File.dirname(stylef))
    File.open(stylef, File::WRONLY|File::TRUNC|File::CREAT) do |f|
      f.puts render(style)
    end
    result = `java -jar #{path_to_saxon_jar} -s #{docf} -xsl:#{stylef}`
    FileUtils.rm [docf, stylef]
    result
  end
=end

  def build_navigation(composite)
    html = "<ul>"
    total = composite.size-1
    composite.each_with_index do |node,index|
      if node[:item]
        content = link_to_unless_current(node[:label], document_path(node[:item][:id]))
      else
        content = node[:label]
      end
      html << "<li class=\"#{node[:label]=~/[0-9]+/ ? 'pagenum' : ''}\">" + content
      html << build_navigation(node[:children]) if node[:children].size>0
      html << "</li>"
    end
    html << "</ul>"
  end
  
end