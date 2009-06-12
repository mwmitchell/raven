# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def html_top
    @html_top ||= []
  end
  
  def html_bottom
    @html_bottom ||= []
  end
  
  def nav_tree(nav, html='')
    html << '<ul>'
    nav['children'].each do |child|
      html << '<li>' + link_to_unless_current(child['label'], document_path(child['id']))
      nav_tree(child, html) unless child['children'].empty?
      html << '</li>'
    end
    html + '</ul>'
  end
  
  def nav_options_for_select(nav, html='', depth=0)
    nav['children'].each do |child|
      html << "<option value=\"#{child['id']}\">#{'-' * depth}#{child['label']}</option>"
      nav_options_for_select(child, html, (depth+1)) unless child['children'].empty?
    end
    html
  end
  
end