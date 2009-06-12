require 'rubygems'
require 'test/unit'
require 'shoulda'

RAILS_ROOT = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)

require 'raven'

class RavenNavBuilderTest < Test::Unit::TestCase

  context 'NavBuilder #build return object, using :first_child=>true' do
    
    setup do
      @nb = Raven::NavBuilder::Base.new 'mitchell'
      @root = @nb.build 'Poems, by Matt Mitchell', 'poems', :first_child=>true do |root|
        root.item 'Tiger Barn', 'poem1', :first_child=>true do |poem1|
          poem1.item 'Page 1', 1, :first_child=>true do |page1|
            #page1.doc[:text] = 'Last summer, whilst you dithered endlessly...'
            page1.item 'fragment', 2 do |fragment|
              fragment.doc[:text] = 'a fragment'
            end
          end
          poem1.item 'Page 2', 2 do |page2|
            page2.doc[:text] = 'My dear, I ate a tiger barn for you.'
          end
        end
      end
    end
    
    should "have a navigation result hierarchy where the 2-top-level nodes link to Page 1, because they're using :first_child=>true" do
      expected = {:label=>"Poems, by Matt Mitchell",
       :id=>"mitchell-poems-poem1-1-2",
       :children=>
        [{:label=>"Tiger Barn",
          :id=>"mitchell-poems-poem1-1-2",
          :children=>
           [{:label=>"Page 1",
             :id=>"mitchell-poems-poem1-1-2",
             :children=>
              [{:label=>"fragment",
                :id=>"mitchell-poems-poem1-1-2",
                :children=>[]}]},
            {:label=>"Page 2", :id=>"mitchell-poems-poem1-2", :children=>[]}]}]}
      assert_equal expected, @root.navigation
    end
    
    should 'have 2 documents; page 1 and page 2' do
      expected = [{:text=>"a fragment", :id=>"mitchell-poems-poem1-1-2"},
       {:text=>"My dear, I ate a tiger barn for you.",
        :id=>"mitchell-poems-poem1-2"}]
      assert_equal expected, @root.documents
    end
    
  end
  
  context 'NavBuilder #build return object, WITHOUT using :first_child=>true' do
    
    setup do
      @nb = Raven::NavBuilder::Base.new 'mitchell'
      @root = @nb.build 'Poems, by Matt Mitchell', 'poems' do |root|
        root.doc[:text] = 'Here are my poems...'
        root.item 'Tiger Barn', 'poem1' do |poem1|
          poem1.doc[:text] = 'This is a poem about fishing in the North Atlantic'
          poem1.item 'Page 1', 1 do |page1|
            page1.doc[:text] = 'Last summer, whilst you dithered endlessly...'
          end
          poem1.item 'Page 2', 2 do |page2|
            page2.doc[:text] = 'My dear, I ate a tiger barn for you.'
          end
        end
      end
    end
    
    should "have a navigation result hierarchy where all nodes are included, and each node links to a unique doc id" do
      expected = {:label=>"Poems, by Matt Mitchell",
       :id=>"mitchell-poems",
       :children=>
        [{:label=>"Tiger Barn",
          :id=>"mitchell-poems-poem1",
          :children=>
           [{:label=>"Page 1", :id=>"mitchell-poems-poem1-1", :children=>[]},
            {:label=>"Page 2", :id=>"mitchell-poems-poem1-2", :children=>[]}]}]}
      assert_equal expected, @root.navigation
    end
    
    should 'have 4 documents' do
      expected = [{:text=>"Here are my poems...", :id=>"mitchell-poems"},
       {:text=>"This is a poem about fishing in the North Atlantic",
        :id=>"mitchell-poems-poem1"},
       {:text=>"Last summer, whilst you dithered endlessly...",
        :id=>"mitchell-poems-poem1-1"},
       {:text=>"My dear, I ate a tiger barn for you.",
        :id=>"mitchell-poems-poem1-2"}]
      docs = @root.documents
      assert_equal 4, docs.size
      assert_equal expected, docs
    end
    
  end

end