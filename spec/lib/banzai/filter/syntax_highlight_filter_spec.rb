require 'spec_helper'

describe Banzai::Filter::SyntaxHighlightFilter do
  include FilterSpecHelper

  shared_examples "XSS prevention" do |lang|
    it "escapes HTML tags" do
      # This is how a script tag inside a code block is presented to this filter
      # after Markdown rendering.
      result = filter(%{<pre lang="#{lang}"><code>&lt;script&gt;alert(1)&lt;/script&gt;</code></pre>})

      expect(result.to_html).not_to include("<script>alert(1)</script>")
      expect(result.to_html).to include("alert(1)")
    end
  end

  context "when no language is specified" do
    it "highlights as plaintext" do
      result = filter('<pre><code>def fun end</code></pre>')

      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight plaintext" lang="plaintext" v-pre="true"><code><span id="LC1" class="line" lang="plaintext">def fun end</span></code></pre>')
    end

    include_examples "XSS prevention", ""
  end

  context "when a valid language is specified" do
    it "highlights as that language" do
      result = filter('<pre><code lang="ruby">def fun end</code></pre>')

      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight ruby" lang="ruby" v-pre="true"><code><span id="LC1" class="line" lang="ruby"><span class="k">def</span> <span class="nf">fun</span> <span class="k">end</span></span></code></pre>')
    end

    include_examples "XSS prevention", "ruby"
  end

  context "when an invalid language is specified" do
    it "highlights as plaintext" do
      result = filter('<pre><code lang="gnuplot">This is a test</code></pre>')

      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight plaintext" lang="plaintext" v-pre="true"><code><span id="LC1" class="line" lang="plaintext">This is a test</span></code></pre>')
    end

    include_examples "XSS prevention", "gnuplot"
  end

  context "languages that should be passed through" do
    %w(math plantuml).each do |lang|
      context "when #{lang} is specified" do
        it "highlights as plaintext but with the correct language attribute and class" do
          result = filter(%{<pre><code lang="#{lang}">This is a test</code></pre>})

          expect(result.to_html).to eq(%{<pre class="code highlight js-syntax-highlight #{lang}" lang="#{lang}" v-pre="true"><code><span id="LC1" class="line" lang="#{lang}">This is a test</span></code></pre>})
        end

        include_examples "XSS prevention", lang
      end
    end
  end

  context "when Rouge lexing fails" do
    before do
      allow_any_instance_of(Rouge::Lexers::Ruby).to receive(:stream_tokens).and_raise(StandardError)
    end

    it "highlights as plaintext" do
      result = filter('<pre><code lang="ruby">This is a test</code></pre>')

      expect(result.to_html).to eq('<pre class="code highlight js-syntax-highlight " lang="" v-pre="true"><code><span id="LC1" class="line" lang="">This is a test</span></code></pre>')
    end

    include_examples "XSS prevention", "ruby"
  end

  context "when Rouge lexing fails after a retry" do
    before do
      allow_any_instance_of(Rouge::Lexers::PlainText).to receive(:stream_tokens).and_raise(StandardError)
    end

    it "does not add highlighting classes" do
      result = filter('<pre><code>This is a test</code></pre>')

      expect(result.to_html).to eq('<pre><code>This is a test</code></pre>')
    end

    include_examples "XSS prevention", "ruby"
  end
end
