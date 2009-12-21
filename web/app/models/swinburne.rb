class Swinburne
  
  include RSolr::Ext::Model
  
  def self.find input_params
    search_params = {
      :q => input_params[:q],
      :qt => "dismax",
      :fq => %(collection_id:"swinburne"),
      'facet.field' => ['poem_title_s'],
      'facet' => true,
      'facet.mincount' => 1,
      :rows => 2_000_000_000,
      'hl' => 'true',
      'hl.fl' => 'xml_t',
      'hl.fragsize' => 100,
      :fl => 'id,score,poem_title_s,local_id,page_number_s'
    }.merge(input_params)
    connection.find search_params
  end
  
  def self.find_by_poem_title_id title_id
    connection.find(
      :q=>%(poem_title_id:"#{poem_title_id}"),
      :fq => %(collection_id:"swinburne"),
      :rows => 2_000_000_000,
      'facet' => true,
      'facet.field' => ['variant_s'],
      'facet' => true,
      'facet.mincount' => 1
    )
  end
  
  def self.find_by_local_id local_id
    connection.find :q => %(id:"swinburne-#{local_id}"), :rows => 1
  end
  
  # think "more like this"...
  def self.find_relatives_of solr_doc
    Swinburne.find :fq => [%(collapse_id:"#{solr_doc[:collapse_id]}"), %(poem_title_facet:"#{solr_doc[:poem_title_facet]}")], :rows => 999999
  end
  
end