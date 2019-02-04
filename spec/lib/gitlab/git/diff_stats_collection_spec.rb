# frozen_string_literal: true

require "spec_helper"

describe Gitlab::Git::DiffStatsCollection do
  let(:stats_a) do
    double(Gitaly::DiffStats, additions: 10, deletions: 15, path: 'foo')
  end

  let(:stats_b) do
    double(Gitaly::DiffStats, additions: 5, deletions: 1, path: 'bar')
  end

  let(:diff_stats) { [stats_a, stats_b] }
  let(:collection) { described_class.new(diff_stats) }

  describe '#find_by_path' do
    it 'returns stats by path when found' do
      expect(collection.find_by_path('foo')).to eq(stats_a)
    end

    it 'returns nil when stats is not found by path' do
      expect(collection.find_by_path('no-file')).to be_nil
    end
  end

  describe '#paths' do
    it 'returns only modified paths' do
      expect(collection.paths).to eq %w[foo bar]
    end
  end
end
