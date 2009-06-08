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
    @pnr ||= (
      s = []
      current_n = self
      while current_n.previous_sibling
        s << current_n.previous_sibling
        if current_n.parent
          s += current_n.parent.previous_nodes_recursive
        end
        current_n = current_n.previous_sibling
      end
      s.uniq
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
    
    def fragment(source, pattern, include_first=false, &blk)
      
      # until I get this path stuff straight, gotta parse twice :(
      source = source.is_a?(String) ? Nokogiri::XML(source) : Nokogiri::XML(source.to_xml)
      
      if include_first==true
        # get the first set of nodes before the first fragment
        first_found = nil
        source_copy = source.dup
        source_copy.flatten.each do |e|
          first_found ||= e.name == pattern
          e.remove if first_found
        end
        yield source_copy if first_found
      end
      
      source.search(pattern).each do |snode|
        
        source_copy = source.dup
        
        #puts "node path: #{snode.path}"
        
        node = source_copy.at(snode.path)
        
        #puts "THE NODE: #{node.to_xml}"
        
        found = nil
        after = nil
        
        node.previous_nodes_recursive.each{|n|n.remove}
        
        flattened = source_copy.flatten
        flattened -= [source_copy]
        flattened.each do |e|
          
          # have we found the current (first) fragment node?
          if found.nil? and e.path == node.path
            #puts "found node: #{node.to_xml}"
            found = true
            next
          end
          
          after ||= e.name == node.name
          
          #puts "before after"
          
          next unless after==true
          
          #puts "removing #{e.to_xml}"
          
          e.remove
          
        end
        
        yield source_copy
        
      end
      
    end
  
  end
  
end