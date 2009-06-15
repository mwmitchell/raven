require 'rubygems'
require 'test/unit'
require 'shoulda'

RAILS_ROOT = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)

require 'raven'

class RavenNavigationBuilderTest < Test::Unit::TestCase
  
  def sample_nav(builder_opts={})
    nav = Raven::Navigation::Builder.new(builder_opts)
    nav.build('Swinburne') do |root|
      root.item 'Description of Collection' do |desc|
        desc.item 'Item One', :xml=>'<root/>'
      end
    end
    nav
  end
  
  should "export simple hashes correctly" do
    expected = {:id=>"0",
     :children=>
      [{:id=>"1",
        :children=>[{:id=>"2", :children=>[], :label=>"Item One"}],
        :label=>"Description of Collection"}],
     :label=>"Swinburne"}
    assert_equal expected, sample_nav.export
  end

  should "export simple hashes correctly with an id prefix" do
    expected = {:id=>"sb-0",
     :children=>
      [{:id=>"sb-1",
        :children=>[{:id=>"sb-2", :children=>[], :label=>"Item One"}],
        :label=>"Description of Collection"}],
     :label=>"Swinburne"}
    assert_equal expected, sample_nav(:prefix=>'sb').export
  end
  
  should "be able to change the exported nodes, within a block" do
    expected = {:id=>"prefix-0",
     :children=>
      [{:id=>"prefix-1",
        :children=>[{:id=>"prefix-2", :children=>[], :label=>"Item One"}],
        :label=>"Description of Collection"}],
     :label=>"Swinburne"}
    # prefix the ids with "prefix-"
    result = sample_nav.export {|item| item[:id] = "prefix-#{item[:id]}" }
    assert_equal(expected, result)
  end
  
  should "flatten all real nodes (not the plain hash objects that the #xport method returns)" do
    items = sample_nav.flatten
    assert_equal 3, items.size
    assert_equal "Swinburne", items[0].label
    assert_equal "Description of Collection", items[1].label
    assert_equal "Item One", items[2].label
    assert_equal '<root/>', items[2].opts[:xml]
  end
  
  should "raise an error if the object is NOT a Hash" do
    assert_raise RuntimeError do
      Raven::Navigation.dump(self.sample_nav, 'test')
    end
  end
  
  def recursive_symbolize_keys! hash
    hash.symbolize_keys!
    hash.values.each do |v|
      if v.is_a?(Hash)
        # do the sub hashes
        recursive_symbolize_keys!(v) if v.is_a?(Hash)
      elsif v.is_a?(Array)
        # do the arrays too...
        v.each {|vv| recursive_symbolize_keys!(vv) if vv.is_a?(Hash) }
      end
    end
  end
  
  context 'Raven::Navigation::Builder' do
    
    setup do
      @f = File.join(File.dirname(__FILE__), 'test.json')
    end
    
    teardown do
      # remove the previous file
      FileUtils.rm(@f) rescue nil
    end
    
    should "save a navigation object in json format and be able to load it back up..." do
      Raven::Navigation.base_dir = File.dirname(__FILE__)
      nav = self.sample_nav.export
      json = nav.to_json
      Raven::Navigation.dump(nav, 'test')
      assert_equal json, File.read(@f).chomp
    
      loaded = Raven::Navigation.load('test')
      # the json de-serializer restores keys to strings, our sample nav used symbols
      # so we recursively change them to symbols here:
      recursive_symbolize_keys! loaded
      assert_equal nav, loaded
    end
  
  end
  
end