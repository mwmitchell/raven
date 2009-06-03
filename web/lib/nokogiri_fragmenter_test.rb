
require File.join(File.dirname(__FILE__), 'nokogiri_fragmenter.rb')

data = %Q(
<root>
  <p>START</p>
  <pb id="pb0"/>
  <p>Testing</p>
  <div>
    <pre>
      <span>should not be in the pb#pb0</span>
      <pb id="pb1"/>
      <span>should only be for pb1</span>
    	<div id="one">
    		<p>1 some text</p>
    		<p>2 some text</p>
    		<p>3 some text</p>
    		<p id="prePb2">4 some text</p>
    		<pb id="pb2"/>
    		<p>5 some text</p>
    		<p>6 some text</p>
    		<div id="one-one">
    			<p>1-1 some text</p>
    			<p>1-2 some text</p>
    			<p>1-3 some text</p>
    			<pb id="pb3"/>
    			<p>1-4 some text</p>
    			<p>1-5 some text</p>
    		</div>
    	</div>
    	<pb id="pb4"/>
    	<div id="two">
    		<p>1 some text</p>
    		<p>2 some text</p>
    		<p>3 some text</p>
    		<p>4 some text</p>
    		<pb id="pb5"/>
    		<p>5 some text</p>
    		<p>6 some text</p>
    		<div id="two-one">
    			<pb id="pb6"/>
    			<p>2-1 some text</p>
    			<p>2-2 some text</p>
    			<p>2-3 some text</p>
    			<p>2-4 some text</p>
    			<p>3-5 some text</p>
    		</div>
    		<p id="ending1">ENDING TEXT 1</p>
    	</div>
    </pre>
  	<p id="ending2">ENDING TEXT 2</p>
  </div>
</root>
)

expected = [
'<?xml version="1.0"?>
<root>
  <p>START</p>
  </root>
',
'<?xml version="1.0"?>
<root><pb id="pb0"/>
  <p>Testing</p>
  <div>
    <pre>
      <span>should not be in the pb#pb0</span>
      </pre></div></root>
',
'<?xml version="1.0"?>
<root>
  <div>
    <pre><pb id="pb1"/>
      <span>should only be for pb1</span>
    	<div id="one">
    		<p>1 some text</p>
    		<p>2 some text</p>
    		<p>3 some text</p>
    		<p id="prePb2">4 some text</p>
    		</div></pre>
  </div>
</root>
',
'<?xml version="1.0"?>
<root>
  <div>
    <pre>
      <div id="one"><pb id="pb2"/>
    		<p>5 some text</p>
    		<p>6 some text</p>
    		<div id="one-one">
    			<p>1-1 some text</p>
    			<p>1-2 some text</p>
    			<p>1-3 some text</p>
    			</div></div>
    </pre>
  </div>
</root>
',
'<?xml version="1.0"?>
<root>
  <div>
    <pre><div id="one"><div id="one-one"><pb id="pb3"/>
    			<p>1-4 some text</p>
    			<p>1-5 some text</p>
    		</div>
    	</div>
    	</pre>
  </div>
</root>
',
'<?xml version="1.0"?>
<root>
  <div>
    <pre><pb id="pb4"/>
    	<div id="two">
    		<p>1 some text</p>
    		<p>2 some text</p>
    		<p>3 some text</p>
    		<p>4 some text</p>
    		</div></pre>
  </div>
</root>
',
'<?xml version="1.0"?>
<root>
  <div>
    <pre>
      <div id="two"><pb id="pb5"/>
    		<p>5 some text</p>
    		<p>6 some text</p>
    		<div id="two-one">
    			</div></div>
    </pre>
  </div>
</root>
',
'<?xml version="1.0"?>
<root><div><pre><div id="two"><div id="two-one"><pb id="pb6"/>
    			<p>2-1 some text</p>
    			<p>2-2 some text</p>
    			<p>2-3 some text</p>
    			<p>2-4 some text</p>
    			<p>3-5 some text</p>
    		</div>
    		<p id="ending1">ENDING TEXT 1</p>
    	</div>
    </pre>
  	<p id="ending2">ENDING TEXT 2</p>
  </div>
</root>
'
]

#data = File.read('../collections/swinburne/tei-swinburne3.xml')

DATA = data
EXPECTED = expected

require 'benchmark'
upto = 10

xml = Nokogiri::XML(data)

Benchmark.bmbm do |x|
  x.report('fragmenter') do
    upto.times do
      NokogiriFragmenter.fragment(data, 'pb') do |page|
        
      end
    end
  end
end

require 'test/unit'

class NokogiriFramenterTest < Test::Unit::TestCase
  
  def test_expected
    i = 0
    NokogiriFragmenter.fragment(DATA, 'pb') do |page|
      assert_equal EXPECTED[i], page.to_s
      i += 1
    end
  end
  
end