# frozen_string_literal: true

require 'spec_helper'

# TODO: This is now a legacy filter, and is only used with the Ruby parser.
# The current markdown parser now properly handles multiline block quotes.
# The Ruby parser is now only for benchmarking purposes.
# issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
RSpec.describe Banzai::Filter::BlockquoteFenceLegacyFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:context) { { markdown_engine: Banzai::Filter::MarkdownFilter::CMARK_ENGINE } }

  it 'converts blockquote fences to blockquote lines', :unlimited_max_formatted_output_length do
    content = File.read(Rails.root.join('spec/fixtures/blockquote_fence_legacy_before.md'))
    expected = File.read(Rails.root.join('spec/fixtures/blockquote_fence_legacy_after.md'))

    output = filter(content, context)

    expect(output).to eq(expected)
  end

  it 'does not require newlines at start or end of string' do
    expect(filter(">>>\ntest\n>>>", context)).to eq("\n> test\n")
  end

  it 'allows trailing whitespace on blockquote fence lines' do
    expect(filter(">>> \ntest\n>>> ", context)).to eq("\n> test\n")
  end

  context 'when incomplete blockquote fences with multiple blocks are present' do
    it 'does not raise timeout error' do
      test_string = ">>>#{"\n```\nfoo\n```" * 20}"

      expect do
        Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { filter(test_string, context) }
      end.not_to raise_error
    end
  end
end
