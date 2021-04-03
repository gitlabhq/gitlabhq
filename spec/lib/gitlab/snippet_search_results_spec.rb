# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SnippetSearchResults do
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

  describe '#highlight_map' do
    it 'returns the expected highlight map' do
      expect(results.highlight_map('snippet_titles')).to eq({})
    end
  end

  describe '#objects' do
    it 'uses page and per_page to paginate results' do
      snippet2 = create(:snippet, :public, content: 'foo', file_name: 'foo')

      expect(results.objects('snippet_titles', page: 1, per_page: 1).to_a).to eq([snippet2])
      expect(results.objects('snippet_titles', page: 2, per_page: 1).to_a).to eq([snippet])
      expect(results.objects('snippet_titles', page: 1, per_page: 2).count).to eq(2)
    end
  end
end
