class Swinburne
  
  include RSolr::Ext::Model
  
  def self.find input_params
    search_params = {
      :qt => "dismax",
      :fq => %(collection_id:"swinburne"),
      'facet.field' => ['poem_facet'],
      'facet' => true,
      'facet.mincount' => 1
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
  
end