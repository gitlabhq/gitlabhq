# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::CodeLanguageFilter, feature_category: :markdown do
  include FilterSpecHelper

  shared_examples 'XSS prevention' do |lang|
    it 'escapes HTML tags' do
      # This is how a script tag inside a code block is presented to this filter
      # after Markdown rendering.
      result = filter(%(<pre lang="#{lang}"><code>&lt;script&gt;alert(1)&lt;/script&gt;</code></pre>))

      # `(1)` symbols are wrapped by lexer tags.
      expect(result.to_html).not_to match(%r{<script>alert.*</script>})

      # `<>` stands for lexer tags like <span ...>, not &lt;s above.
      expect(result.to_html).to match(%r{alert(<.*>)?\((<.*>)?1(<.*>)?\)})
    end
  end

  context 'when no language is specified' do
    it 'does nothing' do
      result = filter('<pre><code>def fun end</code></pre>')

      expect(result.to_html.delete("\n")).to eq('<pre><code>def fun end</code></pre>')
    end
  end

  context 'when data-lang is empty string' do
    it 'does nothing' do
      result = filter('<pre data-lang=""><code>def fun end</code></pre>')
      expect(result.to_html.delete("\n")).to eq('<pre data-lang=""><code>def fun end</code></pre>')
    end
  end

  context 'when data-lang is whitespace only' do
    it 'does nothing' do
      result = filter('<pre data-lang=" "><code>def fun end</code></pre>')
      expect(result.to_html.delete("\n")).to eq('<pre data-lang=" "><code>def fun end</code></pre>')
    end
  end

  context 'when lang is specified on `pre`' do
    it 'adds data-canonical-lang and data-lang, removes lang attribute' do
      result = filter('<pre lang="ruby"><code>def fun end</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="ruby" data-canonical-lang="ruby"><code>def fun end</code></pre>')
    end

    it 'does not overwrite existing data-lang attribute' do
      doc = filter('<pre data-lang="existing"><code class="language-ruby">code</code></pre>')
      expect(doc.at_css('pre')['data-lang']).to eq('existing')
    end
  end

  context 'when lang is specified on `code`' do
    it 'adds data-canonical-lang and data-lang to `pre` and removes lang attribute' do
      result = filter('<pre><code lang="ruby">def fun end</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="ruby" data-canonical-lang="ruby"><code>def fun end</code></pre>')
    end
  end

  context 'when CSS language class is specified' do
    it 'converts class="language-ruby" to data-lang="ruby"' do
      result = filter('<pre><code class="language-ruby">def fun end</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="ruby" data-canonical-lang="ruby"><code>def fun end</code></pre>')
    end

    it 'handles language with parameters in CSS class' do
      result = filter('<pre><code class="language-ruby:red">def fun end</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="ruby" data-canonical-lang="ruby" data-lang-params="red"><code>def fun end</code></pre>')
    end

    it 'handles plaintext CSS class' do
      result = filter('<pre><code class="language-plaintext">plain text</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="plaintext" data-canonical-lang="plaintext"><code>plain text</code></pre>')
    end

    it 'preserves other CSS classes while converting language class' do
      result = filter('<pre><code class="highlight language-ruby other-class">def fun end</code></pre>')

      expect(result.to_html).to include('data-lang="ruby"')
      expect(result.to_html).to include('class="highlight other-class"')
      expect(result.to_html).not_to include('language-ruby')
    end

    include_examples 'XSS prevention',
      %(ruby data-meta="foo-bar-kux"<script>alert(1)</script>)
  end

  context 'when multiple language sources exist' do
    it 'prioritizes data-lang over CSS class' do
      result = filter('<pre data-lang="python"><code class="language-ruby">def fun end</code></pre>')

      expect(result.at_css('pre')['data-canonical-lang']).to eq('python')
      expect(result.at_css('pre')['data-lang']).to eq('python')
    end

    it 'prioritizes data-lang over lang' do
      result = filter('<pre lang="python" data-lang="ruby"><code>def fun end</code></pre>')

      expect(result.at_css('pre')['data-canonical-lang']).to eq('ruby')
      expect(result.at_css('pre')['data-lang']).to eq('ruby')
    end

    it 'prioritizes CSS class over lang attribute' do
      result = filter('<pre lang="python"><code class="language-ruby">def fun end</code></pre>')

      expect(result.at_css('pre')['data-canonical-lang']).to eq('ruby')
      expect(result.at_css('pre')['data-lang']).to eq('ruby')
    end

    it 'extracts language from code node data-lang when pre node has none' do
      doc = filter('<pre><code data-lang="javascript">code</code></pre>')
      expect(doc.at_css('pre')['data-canonical-lang']).to eq('javascript')
    end

    it 'extracts language from code node lang attribute when pre node has none' do
      doc = filter('<pre><code lang="python">code</code></pre>')
      expect(doc.at_css('pre')['data-canonical-lang']).to eq('python')
    end
  end

  context 'when lang has extra params' do
    let_it_be(:lang_params) { 'foo-bar-kux' }
    let_it_be(:xss_lang) { %(ruby data-meta="foo-bar-kux"&lt;script&gt;alert(1)&lt;/script&gt;) }
    let_it_be(:expected_result) do
      <<~HTML
        <pre data-lang="ruby" data-canonical-lang="ruby" data-lang-params="#{lang_params}">
        <code>This is a test</code></pre>
      HTML
    end

    context 'when lang is specified on `pre`' do
      it 'includes data-lang-params tag with extra information and removes data-meta' do
        result = filter(%(<pre lang="ruby" data-meta="#{lang_params}"><code>This is a test</code></pre>))

        expect(result.to_html.delete("\n")).to eq(expected_result.delete("\n"))
      end
    end

    context 'when lang is specified on `code`' do
      it 'includes data-lang-params tag with extra information and removes data-meta' do
        result = filter(%(<pre><code lang="ruby" data-meta="#{lang_params}">This is a test</code></pre>))

        expect(result.to_html.delete("\n")).to eq(expected_result.delete("\n"))
      end
    end

    context 'when both lang and data-meta specified on `pre`' do
      it 'prefers lang attributes over data-meta' do
        result = filter('<pre data-lang="ruby:test" data-meta="foo-bar"><code>def fun end</code></pre>')

        expect(result.to_html.delete("\n"))
          .to eq('<pre data-lang="ruby" data-canonical-lang="ruby" ' \
            'data-lang-params="test"><code>def fun end</code></pre>')
      end
    end

    include_examples 'XSS prevention', 'ruby'

    include_examples 'XSS prevention',
      %(ruby data-meta="foo-bar-kux"&lt;script&gt;alert(1)&lt;/script&gt;)
  end

  context 'when multiple param delimiters are used' do
    let(:lang) { 'suggestion' }
    let(:lang_params) { '-1+10' }

    let(:expected_result) do
      <<~HTML
      <pre data-lang="#{lang}" data-canonical-lang="#{lang}" data-lang-params="#{lang_params} more-things">
      <code>This is a test</code></pre>
      HTML
    end

    context 'when delimiter is colon' do
      it 'delimits on the first appearance' do
        result = filter(%(<pre data-lang="#{lang}:#{lang_params} more-things"><code>This is a test</code></pre>))

        expect(result.to_html.delete("\n")).to eq(expected_result.delete("\n"))
      end
    end

    include_examples 'XSS prevention', 'ruby'
  end

  context 'when lang has delimiter but no params' do
    it 'treats trailing colon as no params' do
      result = filter('<pre data-lang="ruby:"><code>This is a test</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="ruby" data-canonical-lang="ruby"><code>This is a test</code></pre>')
    end

    it 'treats colon with whitespace as no params' do
      result = filter('<pre data-lang="ruby:   "><code>This is a test</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-lang="ruby" data-canonical-lang="ruby"><code>This is a test</code></pre>')
    end
  end

  it_behaves_like 'pipeline timing check'
end
