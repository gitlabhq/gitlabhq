# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::SuggestionFilter, feature_category: :markdown do
  include FilterSpecHelper

  let(:input) { %(<pre class="code highlight js-syntax-highlight language-suggestion"><code>foo\n</code></pre>) }
  let(:default_context) do
    { suggestions_filter_enabled: true }
  end

  it 'includes `js-render-suggestion` class' do
    doc = filter(input, default_context)
    result = doc.css('code').first

    expect(result[:class]).to include('js-render-suggestion')
  end

  it 'includes no `js-render-suggestion` when filter is disabled' do
    doc = filter(input)
    result = doc.css('code').first

    expect(result[:class]).to be_nil
  end

  context 'multi-line suggestions' do
    let(:data_attr) { Banzai::Filter::CodeLanguageFilter::LANG_PARAMS_ATTR }
    let(:input) { %(<pre class="code highlight js-syntax-highlight language-suggestion" #{data_attr}="-3+2"><code>foo\n</code></pre>) }

    it 'element has correct data-lang-params' do
      doc = filter(input, default_context)
      pre = doc.css('pre').first

      expect(pre[data_attr]).to eq('-3+2')
    end
  end

  it_behaves_like 'pipeline timing check'
end
