# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::RebuildableSetCache, :clean_gitlab_redis_repository_cache, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:gitlab_cache_namespace) { Gitlab::Redis::Cache::CACHE_NAMESPACE }
  let(:cache) { described_class.new(repository) }

  describe 'TTL constants' do
    it 'defines PENDING_EVENT_TTL as 1 hour' do
      expect(described_class::PENDING_EVENT_TTL).to eq(1.hour)
    end

    it 'defines REBUILD_FLAG_TTL as 10 minutes' do
      expect(described_class::REBUILD_FLAG_TTL).to eq(10.minutes)
    end

    it 'defines TRUST_TTL as 1 hour' do
      expect(described_class::TRUST_TTL).to eq(1.hour)
    end
  end

  describe '#cache_key' do
    subject { cache.cache_key(:foo) }

    it 'includes the namespace' do
      is_expected.to eq("#{gitlab_cache_namespace}:foo:#{namespace}:set")
    end
  end

  describe '#pending_key' do
    it 'returns the pending queue key' do
      expect(cache.pending_key(:branch_names))
        .to eq("#{gitlab_cache_namespace}:branch_names:pending:#{namespace}")
    end
  end

  describe '#rebuild_flag_key' do
    it 'returns the rebuild flag key' do
      expect(cache.rebuild_flag_key(:branch_names))
        .to eq("#{gitlab_cache_namespace}:branch_names:rebuild:#{namespace}")
    end
  end

  describe '#trust_key' do
    it 'returns the trust flag key' do
      expect(cache.trust_key(:branch_names))
        .to eq("#{gitlab_cache_namespace}:branch_names:trusted:#{namespace}")
    end
  end

  describe '#trusted?' do
    context 'when trust flag is set' do
      before do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.trust_key(:branch_names), "1")
        end
      end

      it 'returns true' do
        expect(cache.trusted?(:branch_names)).to be true
      end
    end

    context 'when trust flag is not set' do
      it 'returns false' do
        expect(cache.trusted?(:branch_names)).to be false
      end
    end

    context 'when Redis error occurs' do
      before do
        allow(Gitlab::Redis::RepositoryCache).to receive(:with)
          .and_raise(::Redis::ConnectionError)
      end

      it 'returns false' do
        expect(cache.trusted?(:branch_names)).to be false
      end
    end
  end

  describe '#rebuilding?' do
    context 'when rebuild flag is set' do
      before do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.rebuild_flag_key(:branch_names), "1")
        end
      end

      it 'returns true' do
        expect(cache.rebuilding?(:branch_names)).to be true
      end
    end

    context 'when rebuild flag is not set' do
      it 'returns false' do
        expect(cache.rebuilding?(:branch_names)).to be false
      end
    end

    context 'when Redis error occurs' do
      before do
        allow(Gitlab::Redis::RepositoryCache).to receive(:with)
          .and_raise(::Redis::ConnectionError)
      end

      it 'returns false' do
        expect(cache.rebuilding?(:branch_names)).to be false
      end
    end
  end

  describe '#write' do
    subject(:write_cache) { cache.write(:branch_names, %w[main feature]) }

    it 'writes the values to the cache' do
      write_cache

      expect(cache.read(:branch_names)).to contain_exactly('main', 'feature')
    end

    it 'sets expiration on the cache key' do
      write_cache

      expect(cache.ttl(:branch_names)).to be_within(10).of(2.weeks.to_i)
    end

    context 'with large value sets' do
      let(:large_value) { (1..1500).map { |i| "branch-#{i}" } }

      it 'handles values larger than 1000 items' do
        cache.write(:branch_names, large_value)

        expect(cache.read(:branch_names).size).to eq(1500)
      end
    end
  end

  describe '#fetch' do
    let(:block_value) { %w[main develop] }

    context 'when cache exists' do
      before do
        cache.write(:branch_names, %w[cached_branch])
      end

      it 'returns cached value without calling the block' do
        expect { |b| cache.fetch(:branch_names, &b) }.not_to yield_control
        expect(cache.fetch(:branch_names) { block_value }).to contain_exactly('cached_branch')
      end

      it 'does not log the cache hits' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        cache.fetch(:branch_names) { block_value }
      end
    end

    context 'when cache does not exist' do
      it 'calls the block and caches the result' do
        result = cache.fetch(:branch_names) { block_value }

        expect(result).to contain_exactly('main', 'develop')
        expect(cache.read(:branch_names)).to contain_exactly('main', 'develop')
      end

      it 'logs the cache miss' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'RebuildableSetCache cache miss',
            cache_key: :branch_names
          )
        )

        cache.fetch(:branch_names) { block_value }
      end
    end
  end

  describe '#search' do
    before do
      cache.write(:branch_names, %w[main feature/foo feature/bar develop])
    end

    it 'returns matching entries' do
      results = cache.search(:branch_names, 'feature/*') { [] }.to_a

      expect(results).to contain_exactly('feature/foo', 'feature/bar')
    end

    context 'when cache does not exist' do
      it 'populates cache from block before searching' do
        cache.expire(:branch_names)

        results = cache.search(:branch_names, 'feat*') { %w[feat-1 feat-2 other] }.to_a

        expect(results).to contain_exactly('feat-1', 'feat-2')
      end
    end
  end

  describe '#expire' do
    before do
      cache.write(:branch_names, %w[main])
      cache.write(:tag_names, %w[v1.0])
    end

    it 'removes the specified keys' do
      cache.expire(:branch_names)

      expect(cache.exist?(:branch_names)).to be false
      expect(cache.exist?(:tag_names)).to be true
    end

    it 'can expire multiple keys' do
      cache.expire(:branch_names, :tag_names)

      expect(cache.exist?(:branch_names)).to be false
      expect(cache.exist?(:tag_names)).to be false
    end
  end

  describe 'with extra_namespace' do
    let(:cache) { described_class.new(repository, extra_namespace: 'extra') }

    it 'includes extra namespace in cache key' do
      expect(cache.cache_key(:foo)).to eq("#{gitlab_cache_namespace}:foo:#{namespace}:extra:set")
    end
  end

  describe 'with custom expires_in' do
    let(:cache) { described_class.new(repository, expires_in: 1.hour) }

    it 'uses custom expiration' do
      cache.write(:branch_names, %w[main])

      expect(cache.ttl(:branch_names)).to be_within(10).of(1.hour.to_i)
    end
  end
end
