# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ShardHealthCache, :clean_gitlab_redis_cache do
  let(:shards) { %w[foo bar] }

  before do
    described_class.update(shards) # rubocop:disable Rails/SaveBang
  end

  describe '.clear' do
    it 'leaves no shards around' do
      described_class.clear

      expect(described_class.healthy_shard_count).to eq(0)
    end
  end

  describe '.update' do
    it 'returns the healthy shards' do
      expect(described_class.cached_healthy_shards).to match_array(shards)
    end

    it 'replaces the existing set' do
      new_set = %w[test me more]
      described_class.update(new_set) # rubocop:disable Rails/SaveBang

      expect(described_class.cached_healthy_shards).to match_array(new_set)
    end
  end

  describe '.healthy_shard_count' do
    it 'returns the healthy shard count' do
      expect(described_class.healthy_shard_count).to eq(2)
    end

    it 'returns 0 if no shards are available' do
      described_class.update([])

      expect(described_class.healthy_shard_count).to eq(0)
    end
  end

  describe '.healthy_shard?' do
    it 'returns true for a healthy shard' do
      expect(described_class.healthy_shard?('foo')).to be_truthy
    end

    it 'returns false for an unknown shard' do
      expect(described_class.healthy_shard?('unknown')).to be_falsey
    end
  end
end
