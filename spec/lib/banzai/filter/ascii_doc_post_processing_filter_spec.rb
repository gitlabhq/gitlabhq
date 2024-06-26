# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AsciiDocPostProcessingFilter, feature_category: :wiki do
  include FilterSpecHelper

  it "adds class for elements with data-math-style" do
    result = filter('<pre data-math-style="inline">some code</pre><div data-math>and</div>').to_html
    expect(result).to eq('<pre data-math-style="inline" class="js-render-math">some code</pre><div data-math>and</div>')
  end

  it "adds class for elements with data-mermaid-style" do
    result = filter('<pre data-mermaid-style="display">some code</pre>').to_html

    expect(result).to eq('<pre data-mermaid-style="display" class="js-render-mermaid">some code</pre>')
  end

  it "keeps content when no data-math-style found" do
    result = filter('<pre>some code</pre><div data-math>and</div>').to_html
    expect(result).to eq('<pre>some code</pre><div data-math>and</div>')
  end

  it_behaves_like 'pipeline timing check'
end
