require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'raven'

class RavenMaterializedPathTest < Test::Unit::TestCase
  
  should 'build a composite object from a set of paths' do
    set = [
    	{:id=>1, :path=>'A::poems::one::1'},
    	{:id=>2, :path=>'A::poems::one::2'},
    	{:id=>5, :path=>'A::poems::two::11'},
    	{:id=>7, :path=>'A::b::c::a'},
    	{:id=>8, :path=>'A::b::c::a::11'},
    	{:id=>100, :path=>'Z::100'},
    	{:id=>7, :path=>'A::b::c::d'}
    ]
    root = Raven::MaterializedPath.set_to_composite(set)
    
    # the root has "a" and "b"
    assert_equal 2, root.children.size
    
    assert_equal ['A', 'Z'], root.children.map{|n|n.label}
    
    a = root.children[0]
    assert_equal 'A', a.label
    assert_equal ['poems', 'b'], a.children.map{|c|c.label}
    
    b = root.children[1]
    assert_equal 'Z', b.label
    assert_equal ['100'], b.children.map{|c|c.label}
    
    # a has poems
    poems = root.children[0].children[0]
    assert_equal 'poems', poems.label
    assert_equal ['one', 'two'], poems.children.map{|c|c.label}
    
    # "poems" has "one" and "two"
    assert_equal 2, poems.children.size
    poems_one = poems.children[0]
    assert_equal 'one', poems_one.label
    assert_equal ['1', '2'], poems_one.children.map{|c|c.label}
    
    poems_two = poems.children[1]
    assert_equal 'two', poems_two.label
    assert_equal ['11'], poems_two.children.map{|c|c.label}
    
    assert_equal ['100'], b.children.map{|c|c.label}
    
    expected_labels = ["poems", "b", "one", "two", "1", "2", "11", "c", "a", "d", "11", "100"]
    assert_equal expected_labels, root.descendants.map{|c|c.label}
    
  end
  
end