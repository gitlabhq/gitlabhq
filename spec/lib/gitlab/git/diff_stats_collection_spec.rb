# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::DiffStatsCollection do
  let(:stats_a) do
    Gitaly::DiffStats.new(additions: 10, deletions: 15, path: 'foo')
  end

  let(:stats_b) do
    Gitaly::DiffStats.new(additions: 5, deletions: 1, path: 'bar')
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

  describe '#real_size' do
    it 'returns the number of modified files' do
      expect(collection.real_size).to eq('2')
    end

    it 'returns capped number when it is bigger than max_files' do
      allow(::Commit).to receive(:diff_max_files).and_return(1)

      expect(collection.real_size).to eq('1+')
    end
  end
end
