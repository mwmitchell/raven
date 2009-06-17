class DocumentsController < ApplicationController
  
  helper_method :facet_fields
  
  def facet_fields
    [:collection_title_s, :title_s, :variant_s]
  end
  
  def index
    @response = solr.find solr_search_params
    @documents = @response.docs
    respond_to do |f|
      f.html
    end
  end
  
  def collection_search
    @response = solr.find solr_search_params.merge({'hl.fragsize'=>50, 'collapse.field'=>nil})
    @documents = @response.docs
    render :layout=>false
  end
  
  def show
    @response = solr.find(:phrases=>{:id => params[:id]})
    @document = @response.docs.first
  end
  
  protected
  
  def solr_search_params
    {
      :q => params[:q],
      :phrase_filters => params[:f],
      :qt => :dismax,
      :per_page => 10,
      :page => params[:page],
      :facets => {
        :fields=>facet_fields
      },
      'collapse.field' => 'collection_id_s',
      'facet.limit' => 10,
      'facet.mincount' => 1,
      'facet.sort' => true,
      'hl' => 'on',
      'hl.fl' => '*_t',
      'hl.snippets' => 5,
      'hl.fragsize' => 150,
      #:fl => 'text',
      #:qf => 'text'
    }
  end
  
end