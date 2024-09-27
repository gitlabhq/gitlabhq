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

  context 'when lang is specified on `pre`' do
    it 'adds data-canonical-lang and removes lang attribute' do
      result = filter('<pre lang="ruby"><code>def fun end</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-canonical-lang="ruby"><code>def fun end</code></pre>')
    end
  end

  context 'when lang is specified on `code`' do
    it 'adds data-canonical-lang to `pre` and removes lang attribute' do
      result = filter('<pre><code lang="ruby">def fun end</code></pre>')

      expect(result.to_html.delete("\n"))
        .to eq('<pre data-canonical-lang="ruby"><code>def fun end</code></pre>')
    end
  end

  context 'when lang has extra params' do
    let_it_be(:lang_params) { 'foo-bar-kux' }
    let_it_be(:xss_lang) { %(ruby data-meta="foo-bar-kux"&lt;script&gt;alert(1)&lt;/script&gt;) }
    let_it_be(:expected_result) do
      <<~HTML
        <pre data-canonical-lang="ruby" data-lang-params="#{lang_params}">
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

    include_examples 'XSS prevention', 'ruby'

    include_examples 'XSS prevention',
      %(ruby data-meta="foo-bar-kux"&lt;script&gt;alert(1)&lt;/script&gt;)

    include_examples 'XSS prevention',
      %(ruby data-meta="foo-bar-kux"<script>alert(1)</script>)
  end

  context 'when multiple param delimiters are used' do
    let(:lang) { 'suggestion' }
    let(:lang_params) { '-1+10' }

    let(:expected_result) do
      <<~HTML
      <pre data-canonical-lang="#{lang}" data-lang-params="#{lang_params} more-things">
      <code>This is a test</code></pre>
      HTML
    end

    context 'when delimiter is colon' do
      it 'delimits on the first appearance' do
        result = filter(%(<pre lang="#{lang}:#{lang_params} more-things"><code>This is a test</code></pre>))

        expect(result.to_html.delete("\n")).to eq(expected_result.delete("\n"))
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
