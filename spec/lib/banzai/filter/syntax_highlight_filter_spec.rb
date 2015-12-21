require 'spec_helper'

describe Banzai::Filter::SyntaxHighlightFilter, lib: true do
  include FilterSpecHelper

  it 'highlights valid code blocks' do
    result = filter('<pre><code>def fun end</code>')
    expect(result.to_html).to eq("<pre class=\"code highlight js-syntax-highlight plaintext\"><code>def fun end</code></pre>\n")
  end

  it 'passes through invalid code blocks' do
    allow_any_instance_of(described_class).to receive(:block_code).and_raise(StandardError)

    result = filter('<pre><code>This is a test</code></pre>')
    expect(result.to_html).to eq('<pre>This is a test</pre>')
  end
end
