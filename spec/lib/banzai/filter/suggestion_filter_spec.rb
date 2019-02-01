# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::SuggestionFilter do
  include FilterSpecHelper

  let(:input) { "<pre class='code highlight js-syntax-highlight suggestion'><code>foo\n</code></pre>" }
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
end
