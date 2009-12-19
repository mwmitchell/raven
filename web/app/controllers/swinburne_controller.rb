class SwinburneController < ApplicationController
  
  def index
    @response = Swinburne.find :q => params[:q]
  end
  
  def poem
    @response = Swinburne.find_by_poem_slug params[:poem_slug]
  end
  
  def poem_page
    @response = Swinburne.find_by_local_id params[:local_id]
  end
  
end