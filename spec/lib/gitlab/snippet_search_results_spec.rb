require 'spec_helper'

describe Gitlab::SnippetSearchResults do
  let!(:snippet) { create(:snippet, content: 'foo', file_name: 'foo') }

  let(:results) { described_class.new(Snippet.all, 'foo') }

  describe '#total_count' do
    it 'returns the total amount of search hits' do
      expect(results.total_count).to eq(2)
    end
  end

  describe '#snippet_titles_count' do
    it 'returns the amount of matched snippet titles' do
      expect(results.snippet_titles_count).to eq(1)
    end
  end

  describe '#snippet_blobs_count' do
    it 'returns the amount of matched snippet blobs' do
      expect(results.snippet_blobs_count).to eq(1)
    end
  end
end
