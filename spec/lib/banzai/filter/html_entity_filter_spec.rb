require 'spec_helper'

describe Banzai::Filter::HtmlEntityFilter, lib: true do
  include FilterSpecHelper

  let(:unescaped) { 'foo <strike attr="foo">&&&</strike>' }
  let(:escaped) { 'foo &lt;strike attr=&quot;foo&quot;&gt;&amp;&amp;&amp;&lt;/strike&gt;' }

  it 'converts common entities to their HTML-escaped equivalents' do
    output = filter(unescaped)

    expect(output).to eq(escaped)
  end
end
