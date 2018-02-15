require 'spec_helper'

describe Banzai::Filter::HtmlEntityFilter do
  include FilterSpecHelper

  let(:unescaped) { 'foo <strike attr="foo">&&amp;&</strike>' }
  let(:escaped) { 'foo &lt;strike attr=&quot;foo&quot;&gt;&amp;&amp;amp;&amp;&lt;/strike&gt;' }

  it 'converts common entities to their HTML-escaped equivalents' do
    output = filter(unescaped)

    expect(output).to eq(escaped)
  end
end
