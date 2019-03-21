# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::SuggestionFilter do
  include FilterSpecHelper

  let(:input) { %(<pre class="code highlight js-syntax-highlight suggestion"><code>foo\n</code></pre>) }
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
    let(:data_attr) { Banzai::Filter::SyntaxHighlightFilter::LANG_PARAMS_ATTR }
    let(:input) { %(<pre class="code highlight js-syntax-highlight suggestion" #{data_attr}="-3+2"><code>foo\n</code></pre>) }

    context 'feature disabled' do
      before do
        stub_feature_flags(multi_line_suggestions: false)
      end

      it 'removes data-lang-params if it matches a multi-line suggestion param' do
        doc = filter(input, default_context)
        pre = doc.css('pre').first

        expect(pre[data_attr]).to be_nil
      end
    end

    context 'feature enabled' do
      before do
        stub_feature_flags(multi_line_suggestions: true)
      end

      it 'keeps data-lang-params' do
        doc = filter(input, default_context)
        pre = doc.css('pre').first

        expect(pre[data_attr]).to eq('-3+2')
      end
    end
  end
end
