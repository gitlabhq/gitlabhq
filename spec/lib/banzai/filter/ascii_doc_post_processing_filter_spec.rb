require 'spec_helper'

describe Banzai::Filter::AsciiDocPostProcessingFilter do
  include FilterSpecHelper

  it "adds class for elements with data-math-style" do
    result = filter('<pre data-math-style="inline">some code</pre><div data-math>and</div>').to_html
    expect(result).to eq('<pre data-math-style="inline" class="code math js-render-math">some code</pre><div data-math>and</div>')
  end

  it "keeps content when no data-math-style found" do
    result = filter('<pre>some code</pre><div data-math>and</div>').to_html
    expect(result).to eq('<pre>some code</pre><div data-math>and</div>')
  end
end
