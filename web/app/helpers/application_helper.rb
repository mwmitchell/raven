# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def html_top
    @html_top ||= []
  end
  
  def html_bottom
    @html_bottom ||= []
  end
  
end