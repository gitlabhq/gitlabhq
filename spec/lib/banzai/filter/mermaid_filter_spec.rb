# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MermaidFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'adds `js-render-mermaid` class to the `code` tag' do
    doc = filter("<pre class='code highlight js-syntax-highlight mermaid' data-canonical-lang='mermaid' v-pre='true'><code>graph TD;\n  A--&gt;B;\n</code></pre>")
    result = doc.css('code').first

    expect(result[:class]).to include('js-render-mermaid')
  end

  it_behaves_like 'pipeline timing check'
end
