class SwinburneController < ApplicationController
  
  def index
    @response = Swinburne.all :q => params[:q]
  end
  
  def variant
    @response = Swinburne.find_variant_docs params[:variant_id]
  end
  
  def variant_poem
    @response = Swinburne.find_variant_poem params[:variant_id], params[:poem_id]
  end
  
  def variant_poem_page
    @response = Swinburne.find_variant_poem_page params[:variant_id], params[:poem_id], params[:page]
  end
  
  def poem
    @response = Swinburne.find_by_poem_title_id params[:poem_id]
  end
  
  def poem_page
    @response = Swinburne.find_poem_page params[:poem_id], params[:page]
  end
  
end