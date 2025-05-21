# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::RedisHashCounter, :clean_gitlab_redis_shared_state,
  feature_category: :application_instrumentation do
  let(:redis_key) { 'hash_counter_test' }
  let(:hash_key) { 'test_value' }

  subject(:counter) { Class.new.extend(described_class) }

  describe '.hash_increment' do
    it 'increments the hash counter' do
      expect(counter.get_hash(redis_key)[hash_key]).to be_nil
      counter.hash_increment(redis_key, hash_key)
      expect(counter.get_hash(redis_key)[hash_key]).to eq(1)
    end

    it 'can increment the hash counter multiple times' do
      counter.hash_increment(redis_key, hash_key)
      counter.hash_increment(redis_key, hash_key)
      counter.hash_increment(redis_key, hash_key)

      expect(counter.get_hash(redis_key)[hash_key]).to eq(3)
    end

    it 'can increment multiple hash keys in the same redis key' do
      counter.hash_increment(redis_key, 'value1')
      counter.hash_increment(redis_key, 'value2')
      counter.hash_increment(redis_key, 'value1')

      hash = counter.get_hash(redis_key)
      expect(hash['value1']).to eq(2)
      expect(hash['value2']).to eq(1)
    end

    it 'does not have an expiration timestamp by default' do
      counter.hash_increment(redis_key, hash_key)

      expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(-1)
    end

    context 'when expiry is passed as an argument' do
      let(:expiry) { 7.days }

      it 'increments the counter' do
        expect do
          counter.hash_increment(redis_key, hash_key, expiry: expiry)
        end.to change { counter.get_hash(redis_key).fetch(hash_key, 0) }.by(1)
      end

      it 'adds an expiration timestamp to the key' do
        counter.hash_increment(redis_key, hash_key, expiry: expiry)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to be > 0
      end

      it 'does not reset the expiration timestamp when counter is increased again' do
        counter.hash_increment(redis_key, hash_key, expiry: expiry)

        original_expiry = Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }

        counter.hash_increment(redis_key, hash_key, expiry: 14.days)

        # The expiry should remain the same (the original one)
        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(original_expiry)
      end
    end
  end

  describe '.get_hash' do
    before do
      counter.hash_increment(redis_key, 'value1')
      counter.hash_increment(redis_key, 'value2')
      counter.hash_increment(redis_key, 'value1')
    end

    it 'returns a hash of all keys and their counts' do
      result = counter.get_hash(redis_key)

      expect(result).to be_a(Hash)
      expect(result['value1']).to eq(2)
      expect(result['value2']).to eq(1)
    end

    it 'returns integer values' do
      result = counter.get_hash(redis_key)

      expect(result['value1']).to be_a(Integer)
      expect(result['value2']).to be_a(Integer)
    end

    it 'returns empty hash for non-existent keys' do
      result = counter.get_hash('non_existent_key')

      expect(result).to eq({})
    end
  end
end
