require 'rubygems'
require 'test/unit'
require 'shoulda'

require 'materialized_path'

class MaterializedPathTest < Test::Unit::TestCase
  
  should 'build a composite object from a set of paths' do
    set = [
    	{:id=>1, :path=>'a::poems::one::1'},
    	{:id=>2, :path=>'a::poems::one::2'},
    	{:id=>5, :path=>'a::poems::two::11'},
    	{:id=>7, :path=>'a::b::c::a'},
    	{:id=>8, :path=>'a::b::c::a::1'},
    	{:id=>100, :path=>'b::100'},
    ]
    expected = [
      {
        :label=>"a",
        :children=>[
          {
            :label=>"poems",
            :children=>[
              {
                :label=>"one",
                :children=>[
                  {
                    :item=>{:path=>"a::poems::one::1", :id=>1},
                    :label=>"1",
                    :children=>[]
                  },
                  {
                    :item=>{:path=>"a::poems::one::2", :id=>2},
                    :label=>"2",
                    :children=>[]
                  }
                ]
              },
              {
                :label=>"two",
                :children=>[
                  {
                    :item=>{:path=>"a::poems::two::11", :id=>5},
                    :label=>"11",
                    :children=>[]
                  }
                ]
              }
            ]
          },
          {
            :label=>"b",
            :children=>[
              {
                :label=>"c",
                :children=>[
                  {
                    :item=>{:path=>"a::b::c::a", :id=>7},
                    :label=>"a",
                    :children=>[
                      {
                        :item=>{:path=>"a::b::c::a::1", :id=>8},
                        :label=>"1",
                        :children=>[]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        :label=>"b",
        :children=>[
          {
            :label=>"100",
            :item=>{:path=>"b::100", :id=>100},
            :children=>[]
          }
        ]
      }
    ]
    result = MaterializedPath.set_to_composite(set)
    assert_equal expected, result
  end
  
  should 'build a composite object from a set of paths that contain with spaces' do
    set = [
    	{:id=>1, :path=>'a label with spaces::one'},
    	{:id=>2, :path=>'another label with spaces::two'},
  	]
  	expected = [
  	  {
  	    :children=>[
  	      {
  	        :item=>{:path=>"a label with spaces::one", :id=>1},
  	        :children=>[],
  	        :label=>"one"
  	      }
  	    ],
  	    :label=>"a label with spaces"
  	  },
  	  {
  	    :children=>[
  	      {
  	        :item=>{:path=>"another label with spaces::two", :id=>2},
  	        :children=>[],
  	        :label=>"two"
  	      }
  	      ],
  	    :label=>"another label with spaces"
  	  }
    ]
  	result = MaterializedPath.set_to_composite(set)
  	assert_equal expected, result
	end
  
end