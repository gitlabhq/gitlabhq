# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SnippetSearchResults do
  include SearchHelpers

  let_it_be(:snippet) { create(:snippet, content: 'foo', file_name: 'foo') }
  let(:results) { described_class.new(snippet.author, 'foo') }

  describe '#snippet_titles_count' do
    it 'returns the amount of matched snippet titles' do
      expect(results.limited_snippet_titles_count).to eq(1)
    end
  end

  describe '#formatted_count' do
    it 'returns the expected formatted count' do
      expect(results).to receive(:limited_snippet_titles_count).and_return(1234)
      expect(results.formatted_count('snippet_titles')).to eq(max_limited_count)
    end
  end
end
