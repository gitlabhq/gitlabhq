require 'spec_helper'

describe Banzai::Filter::SyntaxHighlightFilter, lib: true do
  include FilterSpecHelper

  context "when no language is specified" do
    it "highlights as plaintext" do
      result = filter('<pre><code>def fun end</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight plaintext"><code>def fun end</code></pre>')
    end
  end

  context "when a valid language is specified" do
    it "highlights as that language" do
      result = filter('<pre><code class="ruby">def fun end</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight ruby"><code><span class="k">def</span> <span class="nf">fun</span> <span class="k">end</span></code></pre>')
    end
  end

  context "when an invalid language is specified" do
    it "highlights as plaintext" do
      result = filter('<pre><code class="gnuplot">This is a test</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight plaintext"><code>This is a test</code></pre>')
    end
  end

  context "when Rouge formatting fails" do
    before do
      allow_any_instance_of(Rouge::Formatter).to receive(:format).and_raise(StandardError)
    end

    it "highlights as plaintext" do
      result = filter('<pre><code class="ruby">This is a test</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight"><code>This is a test</code></pre>')
    end
  end
end
