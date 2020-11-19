# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PreProcessPipeline do
  it 'pre-processes the source text' do
    markdown = <<~MD
      \xEF\xBB\xBF---
      foo: :foo_symbol
      bar: :bar_symbol
      ---

      >>>
      blockquote
      >>>
    MD

    result = described_class.call(markdown, {})

    aggregate_failures do
      expect(result[:output]).not_to include "\xEF\xBB\xBF"
      expect(result[:output]).not_to include '---'
      expect(result[:output]).to include "```yaml\nfoo: :foo_symbol\n"
      expect(result[:output]).to include "> blockquote\n"
    end
  end
end
