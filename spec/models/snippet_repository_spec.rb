# frozen_string_literal: true

require 'spec_helper'

describe SnippetRepository do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:snippet) }
  end

  describe '.find_snippet' do
    it 'finds snippet by disk path' do
      snippet = create(:snippet)
      snippet.track_snippet_repository

      expect(described_class.find_snippet(snippet.disk_path)).to eq(snippet)
    end

    it 'returns nil when it does not find the snippet' do
      expect(described_class.find_snippet('@@unexisting/path/to/snippet')).to be_nil
    end
  end
end
