require 'rubygems'
require 'test/unit'
require 'shoulda'

RAILS_ROOT = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)

require 'raven'

class RavenNavigationBuildRTest < Test::Unit::TestCase
  
  should "should work" do
    r = Raven::Navigation::Build::R.new
    root = r.build do |root|
      root.item :label=>'Description of Collection' do |desc|
        desc.item :label=>'Item One'
      end
    end
    expected = {
      :opts=>{},
      :id=>nil,
      :children=>[
        {
          :opts=>{:label=>"Description of Collection"},
          :id=>0,
          :children=>[
            {
              :opts=>{:label=>"Item One"},
              :id=>1,
              :children=>[]
            }
          ]
        }
      ]
    }
    assert_equal expected, root.export
  end
  
  should 'raise error if all ids are not unique' do
    r = Raven::Navigation::Build::R.new
    assert_raise RuntimeError do
      root = r.build do |root|
        root.item 0 do |item0|
          item0.item 0
        end
      end
    end
  end
  
end