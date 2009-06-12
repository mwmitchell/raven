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
  
  # builds a full UL tree for a document's navigation
  # example usage:
  # <%= build_nav @document.full_nav, :recurse=>true %>
  def build_nav(item, opts={})
    html = '<ul class="nav">'
    label = item['label'].blank? ? '[no title]' : item['label']
    html << "<li>#{link_to_unless_current(label, document_path(item['id']))}"
    if opts[:recurse] and (item['id'] == params[:id] || (item.flatten.any?{|c|c['id']==params[:id]} )) and item['children'].size > 0
      item['children'].each do |n|
        html << build_nav(n, opts)
      end
    end
    html << "</li>"
    html << '</ul>'
  end
  
end