# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::RebuildableSetCache, :clean_gitlab_redis_repository_cache, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:{#{project.id}}" }
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

    it 'defines DRAIN_BATCH_SIZE as 1000' do
      expect(described_class::DRAIN_BATCH_SIZE).to eq(1000)
    end
  end

  describe 'log gating with ref_cache_verbose_logging feature flag' do
    before do
      cache.write(:branch_names, %w[main])
    end

    context 'when ref_cache_verbose_logging is disabled' do
      before do
        stub_feature_flags(ref_cache_verbose_logging: false)
      end

      it 'does not emit info-level logs' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        cache.fetch(:branch_names) { %w[main] }
      end

      it 'still emits error-level logs' do
        allow(Gitlab::Redis::RepositoryCache).to receive(:with).and_wrap_original do |original, &block|
          original.call do |redis|
            allow(redis).to receive(:multi).and_raise(::Redis::ConnectionError, 'Connection refused')
            block.call(redis)
          end
        end

        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: 'rebuild_failed',
            rebuildable_cache: hash_including(
              event: :rebuild_failed,
              cache_key: :branch_names
            )
          )
        )

        expect { cache.write(:branch_names, %w[main feature]) }.to raise_error(::Redis::ConnectionError)
      end
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

  describe '#handle_ref_change' do
    let(:branch_ref) { 'refs/heads/feature-branch' }

    context 'when cache exists and no rebuild in progress' do
      before do
        cache.write(:branch_names, %w[main develop])
      end

      it 'adds a new branch to the cache' do
        cache.handle_ref_change(:branch_names, branch_ref, false)

        expect(cache.read(:branch_names)).to contain_exactly('main', 'develop', 'feature-branch')
      end

      it 'removes a deleted branch from the cache' do
        cache.write(:branch_names, %w[main develop feature-branch])

        cache.handle_ref_change(:branch_names, branch_ref, true)

        expect(cache.read(:branch_names)).to contain_exactly('main', 'develop')
      end

      it 'handles branch names with slashes' do
        cache.handle_ref_change(:branch_names, 'refs/heads/feature/foo/bar', false)

        expect(cache.read(:branch_names)).to include('feature/foo/bar')
      end
    end

    context 'when cache does not exist' do
      it 'does not create the cache' do
        cache.handle_ref_change(:branch_names, branch_ref, false)

        expect(cache.exist?(:branch_names)).to be false
      end
    end

    context 'when rebuild is in progress but cache does not exist' do
      before do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.rebuild_flag_key(:branch_names), '1', ex: 60)
          redis.del(cache.cache_key(:branch_names))
        end
      end

      it 'does not create cache key' do
        cache.handle_ref_change(:branch_names, 'refs/heads/feature', false)

        expect(cache.exist?(:branch_names)).to be false
      end

      it 'still queues event to pending list' do
        cache.handle_ref_change(:branch_names, 'refs/heads/feature', false)

        pending_events = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lrange(cache.pending_key(:branch_names), 0, -1)
        end

        expect(pending_events).to contain_exactly('+feature')
      end

      it 'queues deletion event even when cache does not exist' do
        cache.handle_ref_change(:branch_names, 'refs/heads/old-branch', true)

        pending_events = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lrange(cache.pending_key(:branch_names), 0, -1)
        end

        expect(pending_events).to contain_exactly('-old-branch')
      end
    end

    context 'when rebuild is in progress' do
      before do
        cache.write(:branch_names, %w[main])
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.rebuild_flag_key(:branch_names), "1")
        end
      end

      it 'updates the cache and enqueues event' do
        cache.handle_ref_change(:branch_names, branch_ref, false)

        # Cache is updated immediately
        expect(cache.read(:branch_names)).to contain_exactly('main', 'feature-branch')

        # Event is enqueued for rebuild reconciliation
        Gitlab::Redis::RepositoryCache.with do |redis|
          events = redis.lrange(cache.pending_key(:branch_names), 0, -1)
          expect(events).to contain_exactly('+feature-branch')
        end
      end

      it 'enqueues delete events with minus prefix' do
        cache.write(:branch_names, %w[main feature-branch])

        cache.handle_ref_change(:branch_names, branch_ref, true)

        expect(cache.read(:branch_names)).to contain_exactly('main')

        Gitlab::Redis::RepositoryCache.with do |redis|
          events = redis.lrange(cache.pending_key(:branch_names), 0, -1)
          expect(events).to contain_exactly('-feature-branch')
        end
      end

      it 'sets TTL on pending queue' do
        cache.handle_ref_change(:branch_names, branch_ref, false)

        Gitlab::Redis::RepositoryCache.with do |redis|
          ttl = redis.ttl(cache.pending_key(:branch_names))
          expect(ttl).to be_within(10).of(1.hour.to_i)
        end
      end

      it 'accumulates multiple events in order' do
        cache.handle_ref_change(:branch_names, 'refs/heads/branch-1', false)
        cache.handle_ref_change(:branch_names, 'refs/heads/branch-2', false)
        cache.handle_ref_change(:branch_names, 'refs/heads/branch-1', true)

        Gitlab::Redis::RepositoryCache.with do |redis|
          # LPUSH adds to head, so order is reversed when reading
          events = redis.lrange(cache.pending_key(:branch_names), 0, -1)
          expect(events).to eq(['-branch-1', '+branch-2', '+branch-1'])
        end
      end
    end

    context 'when Redis error occurs during simple_update' do
      before do
        cache.write(:branch_names, %w[main])

        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.trust_key(:branch_names), '1')
        end
      end

      it 'marks cache as untrusted and logs error' do
        call_count = 0
        allow(Gitlab::Redis::RepositoryCache).to receive(:with).and_wrap_original do |original, &block|
          original.call do |redis|
            call_count += 1
            # Only stub the first with call (the one inside simple_update)
            allow(redis).to receive(:eval).and_raise(::Redis::ConnectionError, 'Connection refused') if call_count == 1

            block.call(redis)
          end
        end

        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: 'simple_update_failed',
            rebuildable_cache: hash_including(
              event: :simple_update_failed,
              cache_key: :branch_names
            )
          )
        )

        expect(cache.trusted?(:branch_names)).to be true

        expect { cache.handle_ref_change(:branch_names, branch_ref, false) }.to raise_error(::Redis::ConnectionError)

        expect(cache.trusted?(:branch_names)).to be false
      end
    end

    context 'when Redis error occurs during dual_write' do
      before do
        cache.write(:branch_names, %w[main])
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.rebuild_flag_key(:branch_names), "1")
          redis.set(cache.trust_key(:branch_names), '1')
        end
      end

      it 'marks cache as untrusted and logs error' do
        allow(Gitlab::Redis::RepositoryCache).to receive(:with).and_wrap_original do |original, &block|
          original.call do |redis|
            allow(redis).to receive(:pipelined).and_raise(::Redis::ConnectionError, 'Connection refused')
            block.call(redis)
          end
        end

        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: 'dual_write_failed',
            rebuildable_cache: hash_including(
              event: :dual_write_failed,
              cache_key: :branch_names
            )
          )
        )

        expect(cache.trusted?(:branch_names)).to be true

        expect { cache.handle_ref_change(:branch_names, branch_ref, false) }.to raise_error(::Redis::ConnectionError)

        expect(cache.trusted?(:branch_names)).to be false
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

    it 'marks cache as trusted after write' do
      expect(cache.trusted?(:branch_names)).to be false

      write_cache

      expect(cache.trusted?(:branch_names)).to be true

      ttl = Gitlab::Redis::RepositoryCache.with do |redis|
        redis.ttl(cache.trust_key(:branch_names))
      end

      expect(ttl).to be_within(5).of(described_class::TRUST_TTL.to_i)
    end

    it 'acquires and releases rebuild lock' do
      expect(cache.rebuilding?(:branch_names)).to be false

      # Lock is released after write completes
      write_cache

      expect(cache.rebuilding?(:branch_names)).to be false
    end

    context 'with large value sets' do
      let(:large_value) { (1..1500).map { |i| "branch-#{i}" } }

      it 'handles values larger than 1000 items' do
        cache.write(:branch_names, large_value)

        expect(cache.read(:branch_names).size).to eq(1500)
      end
    end

    context 'when another rebuild is in progress' do
      before do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.rebuild_flag_key(:branch_names), '1')
        end
      end

      it 'skips the rebuild and returns the value' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'rebuild_skipped',
            rebuildable_cache: hash_including(
              event: :rebuild_skipped,
              reason: 'another rebuild in progress'
            )
          )
        )

        result = cache.write(:branch_names, %w[main feature])

        expect(result).to eq(%w[main feature])
        # Cache should not be updated
        expect(cache.exist?(:branch_names)).to be false
      end

      it 'does not drain pending queue' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lpush(cache.pending_key(:branch_names), ['+temp-branch'])
        end

        cache.write(:branch_names, %w[main feature])

        pending_events = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lrange(cache.pending_key(:branch_names), 0, -1)
        end
        expect(pending_events).to contain_exactly('+temp-branch')
      end

      it 'does not clear the rebuild flag' do
        cache.write(:branch_names, %w[main feature])

        rebuild_flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.exists?(cache.rebuild_flag_key(:branch_names))
        end
        expect(rebuild_flag_exists).to be true
      end
    end

    describe 'rebuild flag cleanup on exception' do
      let(:canonical_value) { %w[main develop] }

      context 'when exception occurs during write' do
        it 'clears rebuild flag when drain_pending_events raises' do
          first_call = true
          allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
            if first_call
              first_call = false
              raise Redis::ConnectionError, 'Connection lost'
            end

            method.call(*args)
          end

          expect { cache.write(:branch_names, canonical_value) }.to raise_error(Redis::ConnectionError)

          flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
            redis.exists?(cache.rebuild_flag_key(:branch_names))
          end

          expect(flag_exists).to be false
        end

        it 'allows subsequent rebuild after exception cleanup' do
          first_call = true
          allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
            if first_call
              first_call = false
              raise Redis::ConnectionError, 'Connection lost'
            end

            method.call(*args)
          end

          expect { cache.write(:branch_names, canonical_value) }.to raise_error(Redis::ConnectionError)

          result = cache.write(:branch_names, canonical_value)

          expect(result).to contain_exactly('main', 'develop')
          expect(cache.read(:branch_names)).to contain_exactly('main', 'develop')
          expect(cache.trusted?(:branch_names)).to be true
        end
      end

      context 'when flag was not acquired' do
        before do
          Gitlab::Redis::RepositoryCache.with do |redis|
            redis.set(cache.rebuild_flag_key(:branch_names), '1', ex: 60)
          end
        end

        it 'does not clear existing flag on early return' do
          cache.write(:branch_names, canonical_value)

          flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
            redis.exists?(cache.rebuild_flag_key(:branch_names))
          end

          expect(flag_exists).to be true
        end
      end
    end

    context 'with pending events from concurrent updates' do
      it 'drains pre-existing events and includes them in cache' do
        # Simulate events that arrived before rebuild started
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lpush(cache.pending_key(:branch_names), '+concurrent-branch')
          redis.lpush(cache.pending_key(:branch_names), '-main')
        end

        result = cache.write(:branch_names, %w[main feature])

        # main was in canonical but deleted by event
        # concurrent-branch was added by event
        expect(result).to contain_exactly('feature', 'concurrent-branch')
        expect(cache.read(:branch_names)).to contain_exactly('feature', 'concurrent-branch')
      end

      it 'handles events arriving during rebuild (post-drain)' do
        # We need to simulate events arriving between pre-drain and post-drain
        # This is tricky to test directly, but we can verify the mechanism works
        # by checking that post-drain events are applied

        call_count = 0
        allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
          call_count += 1

          if call_count == 2
            # Simulate event arriving during MULTI/EXEC (between pre and post drain)
            Gitlab::Redis::RepositoryCache.with do |redis|
              redis.lpush(cache.pending_key(:branch_names), '+late-branch')
            end
          end

          method.call(*args)
        end

        result = cache.write(:branch_names, %w[main])

        expect(result).to contain_exactly('main', 'late-branch')
      end

      it 'correctly handles add then delete of same branch' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          # dual_write uses LPUSH (adds to head), drain uses RPOP (removes from tail)
          # This is FIFO: first event pushed is first event popped
          # To simulate chronological order (add first, delete second):
          # LPUSH '+temp-branch' - list: [+temp-branch]
          # LPUSH '-temp-branch' - list: [-temp-branch, +temp-branch]
          # RPOP gets +temp-branch first (add), then -temp-branch (delete)
          redis.lpush(cache.pending_key(:branch_names), '+temp-branch')
          redis.lpush(cache.pending_key(:branch_names), '-temp-branch')
        end

        result = cache.write(:branch_names, %w[main])

        # temp-branch was added then deleted, so should not be in final result
        expect(result).to contain_exactly('main')
      end

      it 'correctly handles delete then add of same branch' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          # To simulate chronological order (delete first, add second):
          # LPUSH '-existing' - list: [-existing]
          # LPUSH '+existing' - list: [+existing, -existing]
          # RPOP gets -existing first (delete), then +existing (add)
          redis.lpush(cache.pending_key(:branch_names), '-existing')
          redis.lpush(cache.pending_key(:branch_names), '+existing')
        end

        result = cache.write(:branch_names, %w[main existing])

        # existing was deleted then re-added, so should be in final result
        expect(result).to contain_exactly('main', 'existing')
      end
    end

    context 'with large number of pending events' do
      it 'handles batch draining correctly' do
        events = Array.new(1500) { |i| "+branch-#{i}" }

        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lpush(cache.pending_key(:branch_names), events)
        end

        result = cache.write(:branch_names, %w[main develop])

        expect(result.size).to eq(1502)
        expect(result).to include('main', 'develop', 'branch-0', 'branch-1499')
      end
    end

    context 'with empty value' do
      it 'writes empty set and processes pending events' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lpush(cache.pending_key(:branch_names), ['+orphan-branch'])
        end

        result = cache.write(:branch_names, [])

        expect(result).to contain_exactly('orphan-branch')
      end
    end

    context 'when Redis error occurs' do
      it 'marks cache as untrusted and re-raises' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.set(cache.trust_key(:branch_names), '1')
        end

        allow(Gitlab::Redis::RepositoryCache).to receive(:with).and_wrap_original do |original, &block|
          original.call do |redis|
            allow(redis).to receive(:multi).and_raise(::Redis::ConnectionError, 'Connection refused')
            block.call(redis)
          end
        end

        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: 'rebuild_failed',
            rebuildable_cache: hash_including(
              event: :rebuild_failed,
              cache_key: :branch_names
            )
          )
        )

        expect { write_cache }.to raise_error(::Redis::ConnectionError)

        expect(cache.trusted?(:branch_names)).to be false
      end
    end
  end

  describe '#fetch' do
    let(:block_value) { %w[main develop] }

    context 'when cache exists and is trusted' do
      before do
        cache.write(:branch_names, %w[cached_branch])
      end

      it 'returns cached value without calling the block' do
        expect { |b| cache.fetch(:branch_names, &b) }.not_to yield_control
        expect(cache.fetch(:branch_names) { block_value }).to contain_exactly('cached_branch')
      end

      it 'logs the cache hit' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'cache_hit',
            rebuildable_cache: hash_including(
              event: :cache_hit,
              cache_key: :branch_names
            )
          )
        )

        cache.fetch(:branch_names) { block_value }
      end

      it 'returns cached data after incremental updates' do
        cache.handle_ref_change(:branch_names, 'refs/heads/hotfix', false)

        result = cache.fetch(:branch_names) { block_value }

        expect(result).to contain_exactly('cached_branch', 'hotfix')
      end
    end

    context 'when cache exists but is not trusted' do
      before do
        cache.write(:branch_names, %w[stale_branch])
        # Manually mark as untrusted
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.del(cache.trust_key(:branch_names))
        end
      end

      it 'calls the block and rebuilds the cache' do
        result = cache.fetch(:branch_names) { block_value }

        expect(result).to contain_exactly('main', 'develop')
        expect(cache.read(:branch_names)).to contain_exactly('main', 'develop')
      end

      it 'marks cache as trusted after rebuild' do
        expect(cache.trusted?(:branch_names)).to be false

        cache.fetch(:branch_names) { block_value }

        expect(cache.trusted?(:branch_names)).to be true
      end

      it 'logs cache miss with trust info' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'cache_miss',
            rebuildable_cache: hash_including(
              event: :cache_miss,
              cache_key: :branch_names,
              exists: true,
              trusted: false
            )
          )
        ).ordered

        allow(Gitlab::AppLogger).to receive(:info)

        cache.fetch(:branch_names) { block_value }
      end
    end

    context 'when cache does not exist' do
      it 'calls the block and caches the result' do
        result = cache.fetch(:branch_names) { block_value }

        expect(result).to contain_exactly('main', 'develop')
        expect(cache.read(:branch_names)).to contain_exactly('main', 'develop')
      end

      it 'logs cache miss with exists info' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'cache_miss',
            rebuildable_cache: hash_including(
              event: :cache_miss,
              cache_key: :branch_names,
              exists: false,
              trusted: false
            )
          )
        ).ordered

        allow(Gitlab::AppLogger).to receive(:info)

        cache.fetch(:branch_names) { block_value }
      end

      it 'sets cache expiry' do
        cache.fetch(:branch_names) { block_value }

        ttl = cache.ttl(:branch_names)
        expect(ttl).to be > 0
        expect(ttl).to be <= 2.weeks
      end
    end

    context 'when block raises an error' do
      it 'propagates the error' do
        expect do
          cache.fetch(:branch_names) { raise StandardError, 'Git fetch failed' }
        end.to raise_error(StandardError, 'Git fetch failed')
      end

      it 'does not populate the cache' do
        begin
          cache.fetch(:branch_names) { raise StandardError }
        rescue StandardError
          # expected
        end

        expect(cache.exist?(:branch_names)).to be false
      end

      it 'does not mark cache as trusted' do
        begin
          cache.fetch(:branch_names) { raise StandardError }
        rescue StandardError
          # expected
        end

        expect(cache.trusted?(:branch_names)).to be false
      end
    end

    context 'with pending events from previous failed rebuild' do
      before do
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lpush(cache.pending_key(:branch_names), ['+orphan-feature', '-main'])
        end
      end

      it 'drains and applies pending events during rebuild' do
        result = cache.fetch(:branch_names) { %w[main develop] }

        expect(result).to contain_exactly('develop', 'orphan-feature')
        expect(cache.read(:branch_names)).to contain_exactly('develop', 'orphan-feature')
      end

      it 'clears the pending queue' do
        cache.fetch(:branch_names) { %w[main develop] }

        pending_events = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.lrange(cache.pending_key(:branch_names), 0, -1)
        end

        expect(pending_events).to be_empty
      end
    end
  end

  describe '#search' do
    context 'when cache exists and is trusted' do
      before do
        cache.write(:branch_names, %w[main feature/foo feature/bar develop])
      end

      it 'returns matching entries without calling the block' do
        expect { |b| cache.search(:branch_names, 'feature/*', &b) }.not_to yield_control

        results = cache.search(:branch_names, 'feature/*') { [] }.to_a
        expect(results).to contain_exactly('feature/foo', 'feature/bar')
      end

      it 'returns matching entries for exact pattern' do
        result = cache.search(:branch_names, 'main') { [] }

        expect(result.to_a).to contain_exactly('main')
      end

      it 'returns matching entries for wildcard suffix pattern' do
        result = cache.search(:branch_names, '*foo') { [] }

        expect(result.to_a).to contain_exactly('feature/foo')
      end

      it 'returns empty enumerator when no matches' do
        result = cache.search(:branch_names, 'nonexistent/*') { [] }

        expect(result.to_a).to be_empty
      end

      it 'returns an Enumerator' do
        result = cache.search(:branch_names, '*') { [] }

        expect(result).to be_an(Enumerator)
      end

      it 'reflects incremental updates' do
        cache.handle_ref_change(:branch_names, 'refs/heads/feature/new-feature', false)

        result = cache.search(:branch_names, 'feature/*') { [] }

        expect(result.to_a).to contain_exactly('feature/foo', 'feature/bar', 'feature/new-feature')
      end

      it 'reflects incremental deletions' do
        cache.handle_ref_change(:branch_names, 'refs/heads/feature/foo', true)

        result = cache.search(:branch_names, 'feature/*') { [] }

        expect(result.to_a).to contain_exactly('feature/bar')
      end
    end

    context 'when cache exists but is not trusted' do
      before do
        cache.write(:branch_names, %w[stale/branch])
        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.del(cache.trust_key(:branch_names))
        end
      end

      it 'rebuilds cache from block before searching' do
        results = cache.search(:branch_names, 'feature/*') { %w[feature/new main] }.to_a

        expect(results).to contain_exactly('feature/new')
        expect(cache.read(:branch_names)).to contain_exactly('feature/new', 'main')
      end

      it 'marks cache as trusted after rebuild' do
        expect(cache.trusted?(:branch_names)).to be false

        cache.search(:branch_names, 'feature/*') { %w[feature/new] }.to_a

        expect(cache.trusted?(:branch_names)).to be true
      end

      it 'does not return stale data' do
        result = cache.search(:branch_names, 'stale/*') { %w[main develop] }

        expect(result.to_a).to be_empty
      end
    end

    context 'when cache does not exist' do
      it 'populates cache from block before searching' do
        results = cache.search(:branch_names, 'feat*') { %w[feat-1 feat-2 other] }.to_a

        expect(results).to contain_exactly('feat-1', 'feat-2')
      end
    end

    context 'with special characters in pattern' do
      before do
        cache.write(:branch_names, %w[release-1.0 release-1.1 release-2.0 test-release])
      end

      it 'handles dot character in pattern' do
        result = cache.search(:branch_names, 'release-1.*') { [] }

        expect(result.to_a).to contain_exactly('release-1.0', 'release-1.1')
      end

      it 'handles question mark single character wildcard' do
        result = cache.search(:branch_names, 'release-?.0') { [] }

        expect(result.to_a).to contain_exactly('release-1.0', 'release-2.0')
      end

      it 'handles bracket character class' do
        result = cache.search(:branch_names, 'release-[12].0') { [] }

        expect(result.to_a).to contain_exactly('release-1.0', 'release-2.0')
      end
    end

    context 'when iterating lazily' do
      before do
        branches = Array.new(100) { |i| "branch-#{i.to_s.rjust(3, '0')}" }
        cache.write(:branch_names, branches)
      end

      it 'supports lazy enumeration' do
        result = cache.search(:branch_names, 'branch-0*') { [] }

        first_five = result.take(5)

        expect(first_five.size).to eq(5)
        expect(first_five).to all(start_with('branch-0'))
      end

      it 'supports chaining with other Enumerable methods' do
        result = cache.search(:branch_names, 'branch-*') { [] }

        count = result.count { |b| b.end_with?('0') }

        expect(count).to eq(10)
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

  describe 'rebuild flag lifecycle' do
    let(:key) { :branch_names }

    it 'sets and clears rebuild flag during write' do
      flag_states = []

      allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
        flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.exists?(cache.rebuild_flag_key(key))
        end
        flag_states << { during_drain: flag_exists }
        method.call(*args)
      end

      cache.write(key, %w[main develop])

      expect(flag_states.first[:during_drain]).to be true

      final_flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
        redis.exists?(cache.rebuild_flag_key(key))
      end
      expect(final_flag_exists).to be false
    end

    it 'sets rebuild flag with correct TTL' do
      allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
        ttl = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.ttl(cache.rebuild_flag_key(key))
        end
        expect(ttl).to be > 0
        expect(ttl).to be <= described_class::REBUILD_FLAG_TTL
        method.call(*args)
      end

      cache.write(key, %w[main develop])
    end
  end

  describe 'integration: push during rebuild lifecycle' do
    let(:key) { :branch_names }

    context 'when push arrives before initial drain' do
      it 'includes the pushed branch in final cache state' do
        cache.write(key, %w[main develop])

        drain_call_count = 0

        allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
          drain_call_count += 1

          cache.handle_ref_change(key, 'refs/heads/feature-from-push', false) if drain_call_count == 1

          method.call(*args)
        end

        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.del(cache.trust_key(key))
          redis.del(cache.rebuild_flag_key(key))
        end

        canonical_branches = %w[main develop hotfix]
        result = cache.write(key, canonical_branches)

        expect(result).to contain_exactly('main', 'develop', 'hotfix', 'feature-from-push')
        expect(cache.read(key)).to contain_exactly('main', 'develop', 'hotfix', 'feature-from-push')
      end

      it 'includes deleted branch in final cache state' do
        cache.write(key, %w[main develop feature-to-delete])

        drain_call_count = 0

        allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
          drain_call_count += 1

          cache.handle_ref_change(key, 'refs/heads/feature-to-delete', true) if drain_call_count == 1

          method.call(*args)
        end

        Gitlab::Redis::RepositoryCache.with do |redis|
          redis.del(cache.trust_key(key))
          redis.del(cache.rebuild_flag_key(key))
        end

        canonical_branches = %w[main develop feature-to-delete]
        result = cache.write(key, canonical_branches)

        expect(result).to contain_exactly('main', 'develop')
        expect(cache.read(key)).to contain_exactly('main', 'develop')
      end
    end
  end

  describe '#write with pending events edge cases' do
    let(:key) { :branch_names }

    context 'when pending queue contains blank events' do
      it 'skips blank events and processes valid ones' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          # Add mix of valid and blank events (LPUSH adds to head, RPOP removes from tail)
          # Order of processing: +valid-branch, '', +another-branch
          redis.lpush(cache.pending_key(key), '+valid-branch')
          redis.lpush(cache.pending_key(key), '')
          redis.lpush(cache.pending_key(key), '+another-branch')
        end

        result = cache.write(key, %w[main])

        # Blank event should be skipped, valid events should be processed
        expect(result).to contain_exactly('main', 'valid-branch', 'another-branch')
      end
    end
  end

  describe 'concurrent rebuilds' do
    let(:key) { :branch_names }
    let(:canonical_value) { %w[main develop] }

    describe 'rebuild flag prevents concurrent rebuilds' do
      context 'when another rebuild is already in progress' do
        before do
          Gitlab::Redis::RepositoryCache.with do |redis|
            redis.set(cache.rebuild_flag_key(key), '1', ex: 60)
          end
        end

        it 'skips rebuild and returns provided value' do
          result = cache.write(key, canonical_value)

          expect(result).to eq(canonical_value)
        end

        it 'does not overwrite existing cache' do
          Gitlab::Redis::RepositoryCache.with do |redis|
            redis.sadd(cache.cache_key(key), %w[existing-branch])
          end

          cache.write(key, canonical_value)

          expect(cache.read(key)).to contain_exactly('existing-branch')
        end

        it 'does not drain pending queue' do
          Gitlab::Redis::RepositoryCache.with do |redis|
            redis.lpush(cache.pending_key(key), ['+pending-branch'])
          end

          cache.write(key, canonical_value)

          pending_events = Gitlab::Redis::RepositoryCache.with do |redis|
            redis.lrange(cache.pending_key(key), 0, -1)
          end

          expect(pending_events).to contain_exactly('+pending-branch')
        end

        it 'does not clear the rebuild flag' do
          cache.write(key, canonical_value)

          flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
            redis.exists?(cache.rebuild_flag_key(key))
          end

          expect(flag_exists).to be true
        end

        it 'does not mark cache as trusted' do
          cache.write(key, canonical_value)

          expect(cache.trusted?(key)).to be false
        end
      end
    end

    describe 'rebuild flag TTL safety' do
      it 'sets rebuild flag with TTL to prevent deadlock' do
        ttl_during_rebuild = nil

        allow(cache).to receive(:drain_pending_events).and_wrap_original do |method, *args|
          ttl_during_rebuild = Gitlab::Redis::RepositoryCache.with do |redis|
            redis.ttl(cache.rebuild_flag_key(key))
          end
          method.call(*args)
        end

        cache.write(key, canonical_value)

        expect(ttl_during_rebuild).to be > 0
        expect(ttl_during_rebuild).to be <= described_class::REBUILD_FLAG_TTL
      end

      it 'clears rebuild flag after successful completion' do
        cache.write(key, canonical_value)

        flag_exists = Gitlab::Redis::RepositoryCache.with do |redis|
          redis.exists?(cache.rebuild_flag_key(key))
        end

        expect(flag_exists).to be false
      end
    end
  end
end
