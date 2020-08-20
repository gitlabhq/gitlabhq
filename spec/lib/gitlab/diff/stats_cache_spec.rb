# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::StatsCache, :use_clean_rails_memory_store_caching do
  subject(:stats_cache) { described_class.new(cachable_key: cachable_key) }

  let(:key) { ['diff_stats', cachable_key, described_class::VERSION].join(":") }
  let(:cachable_key) { 'cachecachecache' }
  let(:stat) { Gitaly::DiffStats.new(path: 'temp', additions: 10, deletions: 15) }
  let(:stats) { Gitlab::Git::DiffStatsCollection.new([stat]) }
  let(:serialized_stats) { stats.map(&:to_h).as_json }
  let(:cache) { Rails.cache }

  describe '#read' do
    before do
      stats_cache.write_if_empty(stats)
    end

    it 'returns the expected stats' do
      expect(stats_cache.read.to_json).to eq(stats.to_json)
    end
  end

  describe '#write_if_empty' do
    context 'when the cache already exists' do
      before do
        Rails.cache.write(key, true)
      end

      it 'does not write the stats' do
        expect(cache).not_to receive(:write)

        stats_cache.write_if_empty(stats)
      end
    end

    context 'when the cache does not exist' do
      it 'writes the stats' do
        expect(cache)
          .to receive(:write)
          .with(key, serialized_stats, expires_in: described_class::EXPIRATION)
          .and_call_original

        stats_cache.write_if_empty(stats)

        expect(stats_cache.read.to_a).to eq(stats.to_a)
      end

      context 'when given non utf-8 characters' do
        let(:non_utf8_path) { '你好'.b }
        let(:stat) { Gitaly::DiffStats.new(path: non_utf8_path, additions: 10, deletions: 15) }

        it 'writes the stats' do
          expect(cache)
            .to receive(:write)
            .with(key, serialized_stats, expires_in: described_class::EXPIRATION)
            .and_call_original

          stats_cache.write_if_empty(stats)

          expect(stats_cache.read.to_a).to eq(stats.to_a)
        end
      end

      context 'when given empty stats' do
        let(:stats) { nil }

        it 'does not write the stats' do
          expect(cache).not_to receive(:write)

          stats_cache.write_if_empty(stats)
        end
      end
    end
  end

  describe '#clear' do
    it 'clears cache' do
      expect(cache).to receive(:delete).with(key)

      stats_cache.clear
    end
  end

  it 'VERSION is set' do
    expect(described_class::VERSION).to be_present
  end

  context 'with multiple cache versions' do
    before do
      stats_cache.write_if_empty(stats)
    end

    it 'does not read from a stale cache' do
      expect(stats_cache.read.to_json).to eq(stats.to_json)

      stub_const('Gitlab::Diff::StatsCache::VERSION', '1.0.new-new-thing')

      stats_cache = described_class.new(cachable_key: cachable_key)

      expect(stats_cache.read).to be_nil

      stats_cache.write_if_empty(stats)

      expect(stats_cache.read.to_json).to eq(stats.to_json)
    end
  end
end
