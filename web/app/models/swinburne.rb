class Swinburne
  
  include RSolr::Ext::Model
  
  def self.find input_params
    search_params = {
      :q => input_params[:q],
      :qt => "dismax",
      :fq => %(collection_id:"swinburne"),
      'facet.field' => ['poem_title_facet'],
      'facet' => true,
      'facet.mincount' => 1,
      :rows => 2_000_000_000,
      :hl => true,
      'hl.fl' => 'xml_t',
      'fl.fragsize' => 100,
      :fl => 'id,score,poem_title_facet,local_id'
    }
    connection.find search_params
  end
  
  def self.find_by_poem_slug slug
    connection.find(
      :q=>%(poem_slug_s:"#{slug}"),
      :fq => %(collection_id:"swinburne"),
      :rows => 2_000_000_000,
      'facet' => true,
      'facet.field' => ['variant_facet'],
      'facet' => true,
      'facet.mincount' => 1
    )
  end
  
  def self.find_by_local_id local_id
    connection.find :q => %(id:"swinburne-#{local_id}"), :rows => 1
  end
  
end