class Swinburne
  
  include RSolr::Ext::Model
  
  ALLROWS = 2_000_000_000
  
  def self.all input_params
    search_params = {
      :q => input_params[:q],
      :qt => "dismax",
      :fq => %(collection_id:"swinburne"),
      'facet.field' => ['poem_title_s', 'variant_s'],
      'facet' => true,
      'facet.mincount' => 1,
      :rows => ALLROWS,
      'hl' => 'true',
      'hl.fl' => 'xml_t',
      'hl.fragsize' => 200,
      :fl => 'id,score,poem_title_s,local_id,page_number_s,variant_s'
    }.merge(input_params)
    connection.find search_params
  end
  
  def self.find_by_poem_title_id poem_title_id
    connection.find(
      :q=>%(poem_title_id:"#{poem_title_id}"),
      :fq => %(collection_id:"swinburne"),
      :rows => ALLROWS,
      'facet' => true,
      'facet.field' => ['variant_s'],
      'facet' => true,
      'facet.mincount' => 1
    )
  end
  
  def self.find_variant_poem variant_id, poem_title_id
    connection.find(
      :q=>%(poem_title_id:"#{poem_title_id}"),
      :fq => [%(collection_id:"swinburne"),%(variant_s:"#{variant_id}")],
      :rows => ALLROWS,
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
    Swinburne.find :fq => [%(collapse_id:"#{solr_doc[:collapse_id]}"), %(poem_title_facet:"#{solr_doc[:poem_title_facet]}")], :rows => ALLROWS
  end
  
end