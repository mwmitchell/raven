class SwinburneController < ApplicationController
  
  def index
    @response = Swinburne.find :q => params[:q]
  end
  
  def poem
    @response = Swinburne.find_by_poem_title_id params[:poem_title_id]
  end
  
  def poem_page
    @response = Swinburne.find_by_local_id params[:poem_title_id]
    @relatives = Swinburne.find_relatives_of @response.docs.first
  end
  
end