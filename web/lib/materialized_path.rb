module MaterializedPath
  
  def self.set_to_composite(set, opts={})
    unless block_given?
      opts[:delimiter]  ||= '::'
      opts[:field]      ||= :path
    end
    c = []
    set.each do |item|
      val = block_given? ? yield(item) : item[opts[:field]].to_s.split(opts[:delimiter])
      acc = nil # define in outer scope to set the :item
      val.compact.inject(c) do |acc,k|
        acc << {:label=>k, :children=>[]} unless acc.any?{|i|i[:label]==k}
        acc.detect{|i|i[:label]==k}[:children]
      end
      acc.last[:item] = item
    end
    c
  end
  
  class Composite
    
    attr_reader :label, :parent, :children, :item
    
    def initialize(node)
      @label = node[:label]
      @parent = node[:parent]
      @children = node[:children]
      @item = node[:item]
    end
    
  end
  
end