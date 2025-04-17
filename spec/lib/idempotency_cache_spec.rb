# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdempotencyCache, feature_category: :hosted_runners do
  let(:key) { 'test_cache:1' }
  let(:ttl) { 5.hours }

  describe '.already_completed?', :clean_gitlab_redis_shared_state do
    subject(:already_completed?) { described_class.already_completed?(key) }

    context 'when cache key does not exist' do
      it 'returns false' do
        expect(already_completed?).to be false
      end
    end

    context 'when cache key exists' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(key, 1, ex: ttl)
        end
      end

      it 'returns true' do
        expect(already_completed?).to be true
      end
    end
  end

  describe '.ensure_idempotency', :clean_gitlab_redis_shared_state do
    it 'yields the block on first call' do
      block_called = false

      described_class.ensure_idempotency(key, ttl) do
        block_called = true
      end

      expect(block_called).to be true
    end

    it 'sets the cache key after executing the block' do
      described_class.ensure_idempotency(key, ttl) { 'test result' }

      expect(described_class.already_completed?(key)).to be true
    end

    it 'does not yield the block on second call with same key' do
      call_count = 0

      2.times do
        described_class.ensure_idempotency(key, ttl) do
          call_count += 1
        end
      end

      expect(call_count).to eq(1)
    end

    it 'yields the block when called with different keys' do
      call_count = 0

      described_class.ensure_idempotency(key, ttl) do
        call_count += 1
      end

      described_class.ensure_idempotency('different key', ttl) do
        call_count += 1
      end

      expect(call_count).to eq(2)
    end

    it 'returns the result of the block on first call' do
      result = described_class.ensure_idempotency(key, ttl) { 'test result' }

      expect(result).to eq('test result')
    end

    it 'returns nil on subsequent calls with same params' do
      described_class.ensure_idempotency(key, ttl) { 'test result' }

      result = described_class.ensure_idempotency(key, ttl) { 'not called' }

      expect(result).to be_nil
    end
  end

  describe '#mark_as_completed!', :clean_gitlab_redis_shared_state do
    let(:cache) { described_class.new(key, ttl) }

    it 'sets the cache key with the specified TTL' do
      redis_double = double

      expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis_double)
      expect(redis_double).to receive(:set).with(key, 1, ex: ttl)

      cache.mark_as_completed!
    end

    it 'makes already_completed? return true' do
      expect(described_class.already_completed?(key)).to be false

      cache.mark_as_completed!

      expect(described_class.already_completed?(key)).to be true
    end
  end

  context 'with expired cache entries', :clean_gitlab_redis_shared_state do
    it 'treats expired entries as not completed' do
      ttl = 1.second # shortest valid redis ttl

      described_class.ensure_idempotency(key, ttl) { 'test result' }

      expect(described_class.already_completed?(key)).to be true

      sleep ttl + 0.01.seconds

      expect(described_class.already_completed?(key)).to be false

      call_count = 0
      described_class.ensure_idempotency(key, ttl) do
        call_count += 1
      end

      expect(call_count).to eq(1)
    end
  end
end
