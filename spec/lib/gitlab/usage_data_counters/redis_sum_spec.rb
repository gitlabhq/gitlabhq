# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::RedisSum, :clean_gitlab_redis_shared_state,
  feature_category: :application_instrumentation do
  let(:redis_key) { 'sum_key' }

  subject(:counter) { Class.new.extend(described_class) }

  describe '.increment_sum_by' do
    it 'counter is increased' do
      expect do
        counter.increment_sum_by(redis_key, 4.2)
        counter.increment_sum_by(redis_key, 2.6)
      end.to change { counter.get(redis_key) }.by(be_within(0.000001).of(6.8))
    end

    it 'does not have an expiration timestamp' do
      counter.increment_sum_by(redis_key, 4.2)

      expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(-1)
    end

    context 'when expiry is passed as an argument' do
      let(:expiry) { 7.days }

      it 'counter is increased' do
        expect do
          counter.increment_sum_by(redis_key, 4.2, expiry: 7.days)
        end.to change { counter.get(redis_key) }.by(4.2)
      end

      it 'adds an expiration timestamp to the key' do
        counter.increment_sum_by(redis_key, 4.2, expiry: 7.days)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to be > 0
      end

      it 'does not reset the expiration timestamp when counter is increased again' do
        counter.increment_sum_by(redis_key, 1.2, expiry: 7.days)

        expiry = Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }

        counter.increment_sum_by(redis_key, 3.4, expiry: 14.days)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(expiry)
      end
    end
  end
end
