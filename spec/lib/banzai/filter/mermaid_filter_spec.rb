require 'spec_helper'

describe Banzai::Filter::MermaidFilter do
  include FilterSpecHelper

  it 'adds `js-render-mermaid` class to the `code` tag' do
    doc = filter("<pre class='code highlight js-syntax-highlight mermaid' lang='mermaid' v-pre='true'><code>graph TD;\n  A--&gt;B;\n</code></pre>")
    result = doc.css('code').first

    expect(result[:class]).to include('js-render-mermaid')
  end
end
