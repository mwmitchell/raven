# This is for breaking up XML docs
# into multiple chunks by a given node type.
# For example, in TEI the "pb" tag exists to signify page breaks...
# Using this code, you could break up the doc into multiple documents
# based on the position/depth of the individual "pb" tags.
#
# Think of this as an xml splitter, like String#split
#

require 'rubygems'
require 'nokogiri'

module NokogiriElementHelpers
  
  # returns a list of nodes starting with this node
  # all the way down through the descendents
  def flatten
    @flattened ||= (
      [self] + self.children.map{|child|child.flatten}.flatten
    )
  end
  
end

module NokogiriNodeHelpers
  
  # returns all previous siblings
  #def previous_siblings
  #  @ps ||= (
  #    previous_sibling ? (previous_sibling.previous_siblings + [previous_sibling]) : []
  #  )
  #end
  
  # returns all previous siblings, plus parent previous siblings (recursively)
  def previous_nodes_recursive
    # if the parent is the document
    # return an array with only the previous sibling in it
    # ... then compact (could be nil)
    @pnr ||= (
      if parent.is_a?(Nokogiri::XML::Document)
        [previous_sibling].compact
      else
        (
          (parent.previous_nodes_recursive) + 
          (previous_sibling ? previous_sibling.previous_nodes_recursive : []) + 
          [previous_sibling]
        ).flatten.uniq.compact
      end
    )
  end
  
end

Nokogiri::XML::Document.send :include, NokogiriElementHelpers

Nokogiri::XML::Element.send :include, NokogiriElementHelpers
Nokogiri::XML::Element.send :include, NokogiriNodeHelpers

Nokogiri::XML::Comment.send :include, NokogiriElementHelpers
Nokogiri::XML::Comment.send :include, NokogiriNodeHelpers

Nokogiri::XML::Text.send :include, NokogiriElementHelpers
Nokogiri::XML::Text.send :include, NokogiriNodeHelpers

class NokogiriFragmenter
  
  class << self
    
    def fragment(source, pattern, &blk)
      
      source = Nokogiri::XML(source) if source.is_a?(String)
      
      # get the first set of nodes before the first fragment
      first_found = nil
      source_copy = source.dup
      
      source_copy.flatten.each do |e|
        first_found ||= e.name == pattern
        e.remove if first_found
      end
      
      yield source_copy if first_found
      
      source.search(pattern).each do |snode|
        
        source_copy = source.dup
        
        node = source_copy.at(snode.path)
        
        found = nil
        after = nil
        
        node.previous_nodes_recursive.each{|n|n.remove}
        
        source_copy.flatten.each do |e|
          
          # skip the document element
          next if e == source_copy
          
          # have we found the current (first) fragment node?
          if found.nil? and e.name == node.name
            found = true
            next
          end
          
          after ||= e.name == node.name
          
          next unless after
          
          e.remove
          
        end
        
        yield source_copy
        
      end
      
    end
  
  end
  
end