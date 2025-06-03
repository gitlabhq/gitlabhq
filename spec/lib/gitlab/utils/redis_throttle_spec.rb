# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::RedisThrottle, :clean_gitlab_redis_shared_state, feature_category: :global_search do
  let!(:cache_key) { "redis_throttle:test:#{SecureRandom.uuid}" }
  let(:period) { 60.seconds }
  let(:redis) { Gitlab::Redis::SharedState.pool.checkout }

  describe '.execute_every' do
    it 'executes the block and returns its result when called for the first time' do
      result = described_class.execute_every(period, cache_key) { 'executed' }

      expect(result).to eq('executed')
    end

    it 'sets the key in Redis with the correct expiration' do
      described_class.execute_every(period, cache_key) { 'executed' }

      expect(redis.exists?(cache_key)).to be true
      expect(redis.ttl(cache_key)).to be_between(0, period)
    end

    it 'returns false and does not execute the block when called again within the period' do
      first_result = described_class.execute_every(period, cache_key) { 'executed' }
      second_result = described_class.execute_every(period, cache_key) { 'should not execute' }

      expect(first_result).to eq('executed')
      expect(second_result).to be(false)
    end

    it 'allows execution again after the period expires' do
      first_result = described_class.execute_every(period, cache_key) { 'first execution' }

      allow(redis).to receive(:set).with(cache_key, 1, ex: period, nx: true).and_return(true)

      second_result = described_class.execute_every(period, cache_key) { 'second execution' }

      expect(first_result).to eq('first execution')
      expect(second_result).to eq('second execution')
    end

    context 'with nil period' do
      it 'always executes the block' do
        first_result = described_class.execute_every(nil, cache_key) { 'first execution' }
        second_result = described_class.execute_every(nil, cache_key) { 'second execution' }

        expect(first_result).to eq('first execution')
        expect(second_result).to eq('second execution')
      end
    end

    context 'in development environment' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'always executes the block when skip_in_development is true' do
        first_result = described_class.execute_every(period, cache_key, skip_in_development: true) { 'first execution' }
        second_result = described_class.execute_every(period, cache_key, skip_in_development: true) do
          'second execution'
        end

        expect(first_result).to eq('first execution')
        expect(second_result).to eq('second execution')
      end

      it 'respects the throttle when skip_in_development is false' do
        first_result = described_class.execute_every(period, cache_key, skip_in_development: false) do
          'first execution'
        end
        second_result = described_class.execute_every(period, cache_key, skip_in_development: false) do
          'should not execute'
        end

        expect(first_result).to eq('first execution')
        expect(second_result).to be(false)
      end
    end
  end
end
