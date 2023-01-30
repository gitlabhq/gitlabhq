# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PreProcessPipeline, feature_category: :team_planning do
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
      expect(result[:output]).to include "```yaml:frontmatter\nfoo: :foo_symbol\n"
      expect(result[:output]).to include "> blockquote\n"
    end
  end

  it 'truncates the text if requested' do
    text = (['foo'] * 10).join(' ')

    result = described_class.call(text, limit: 12)

    expect(result[:output]).to eq('foo foo f...')
  end

  context 'when multiline blockquote' do
    it 'data-sourcepos references correct line in source markdown' do
      markdown = <<~MD
        >>>
        foo
        >>>
      MD

      pipeline_output = described_class.call(markdown, {})[:output]
      pipeline_output = Banzai::Pipeline::PlainMarkdownPipeline.call(pipeline_output, {})[:output]
      sourcepos = pipeline_output.at('blockquote')['data-sourcepos']
      source_line = sourcepos.split(':').first.to_i

      expect(markdown.lines[source_line - 1]).to eq "foo\n"
    end
  end
end
