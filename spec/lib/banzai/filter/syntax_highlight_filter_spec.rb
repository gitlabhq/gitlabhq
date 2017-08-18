require 'spec_helper'

describe Banzai::Filter::SyntaxHighlightFilter do
  include FilterSpecHelper

  context "when no language is specified" do
    it "highlights as plaintext" do
      result = filter('<pre><code>def fun end</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight plaintext" lang="plaintext" v-pre="true"><code><span id="LC1" class="line" lang="plaintext">def fun end</span></code></pre>')
    end
  end

  context "when a valid language is specified" do
    it "highlights as that language" do
      result = filter('<pre><code lang="ruby">def fun end</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight ruby" lang="ruby" v-pre="true"><code><span id="LC1" class="line" lang="ruby"><span class="k">def</span> <span class="nf">fun</span> <span class="k">end</span></span></code></pre>')
    end
  end

  context "when an invalid language is specified" do
    it "highlights as plaintext" do
      result = filter('<pre><code lang="gnuplot">This is a test</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight plaintext" lang="plaintext" v-pre="true"><code><span id="LC1" class="line" lang="plaintext">This is a test</span></code></pre>')
    end
  end

  context "when Rouge formatting fails" do
    before do
      allow_any_instance_of(Rouge::Formatter).to receive(:format).and_raise(StandardError)
    end

    it "highlights as plaintext" do
      result = filter('<pre><code lang="ruby">This is a test</code></pre>')
      expect(result.to_html).to eq('<pre class="code highlight" lang="" v-pre="true"><code>This is a test</code></pre>')
    end
  end
end
