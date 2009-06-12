class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  helper_method :current_user
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  protected
  
  def solr
    @solr ||= Raven.solr
  end
  
end