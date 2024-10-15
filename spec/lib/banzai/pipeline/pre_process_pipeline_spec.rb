# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PreProcessPipeline, feature_category: :markdown do
  it 'pre-processes the source text' do
    markdown = <<~MD
      \xEF\xBB\xBF---
      foo: :foo_symbol
      bar: :bar_symbol
      ---
    MD

    result = described_class.call(markdown, {})

    aggregate_failures do
      expect(result[:output]).not_to include "\xEF\xBB\xBF"
      expect(result[:output]).not_to include '---'
      expect(result[:output]).to include "```yaml:frontmatter\nfoo: :foo_symbol\n"
    end
  end

  it 'truncates the text if requested' do
    text = (['foo'] * 10).join(' ')

    result = described_class.call(text, limit: 12)

    expect(result[:output]).to eq('foo foo f...')
  end
end
