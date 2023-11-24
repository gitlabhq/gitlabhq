# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CircuitBreaker::Store, :clean_gitlab_redis_rate_limiting, feature_category: :ai_abstraction_layer do
  let(:key) { 'key-1' }
  let(:value) { 'value' }
  let(:circuit_store) { described_class.new }

  shared_examples 'reliable circuit breaker store method' do
    it 'does not raise an error when Redis::BaseConnectionError is encountered' do
      allow(Gitlab::Redis::RateLimiting)
        .to receive(:with)
        .and_raise(Redis::BaseConnectionError)

      expect { subject }.not_to raise_error
    end
  end

  describe '#key?' do
    subject(:key?) { circuit_store.key?(key) }

    it_behaves_like 'reliable circuit breaker store method'

    context 'when key exists' do
      before do
        circuit_store.store(key, value)
      end

      it { is_expected.to eq(true) }
    end

    context 'when key does not exist' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#store' do
    let(:options) { {} }

    subject(:store) { circuit_store.store(key, value, options) }

    it_behaves_like 'reliable circuit breaker store method'

    it 'stores value for specified key without expiry by default' do
      expect(store).to eq(value)

      with_redis do |redis|
        expect(redis.get(key)).to eq(value)
        expect(redis.ttl(key)).to eq(-1)
      end
    end

    context 'when expires option is set' do
      let(:options) { { expires: 10 } }

      it 'stores value for specified key with expiry' do
        expect(store).to eq(value)

        with_redis do |redis|
          expect(redis.get(key)).to eq(value)
          expect(redis.ttl(key)).to eq(10)
        end
      end
    end
  end

  describe '#increment' do
    let(:options) { {} }

    subject(:increment) { circuit_store.increment(key, 1, options) }

    it_behaves_like 'reliable circuit breaker store method'

    context 'when key does not exist' do
      it 'sets key and increments value' do
        increment

        with_redis do |redis|
          expect(redis.get(key).to_i).to eq(1)
          expect(redis.ttl(key)).to eq(-1)
        end
      end

      context 'with expiry' do
        let(:options) { { expires: 10 } }

        it 'sets key and increments value with expiration' do
          increment

          with_redis do |redis|
            expect(redis.get(key).to_i).to eq(1)
            expect(redis.ttl(key)).to eq(10)
          end
        end
      end
    end

    context 'when key exists' do
      before do
        circuit_store.store(key, 1)
      end

      it 'increments value' do
        increment

        with_redis do |redis|
          expect(redis.get(key).to_i).to eq(2)
          expect(redis.ttl(key)).to eq(-1)
        end
      end

      context 'with expiry' do
        let(:options) { { expires: 10 } }

        it 'increments value with expiration' do
          increment

          with_redis do |redis|
            expect(redis.get(key).to_i).to eq(2)
            expect(redis.ttl(key)).to eq(10)
          end
        end
      end
    end
  end

  describe '#load' do
    subject(:load) { circuit_store.load(key) }

    it_behaves_like 'reliable circuit breaker store method'

    context 'when key exists' do
      before do
        circuit_store.store(key, value)
      end

      it 'returns the value of the key' do
        expect(load).to eq(value)
      end
    end

    context 'when key does not exist' do
      it 'returns nil' do
        expect(load).to be_nil
      end
    end
  end

  describe '#values_at' do
    let(:other_key) { 'key-2' }
    let(:other_value) { 'value-2' }

    subject(:values_at) { circuit_store.values_at(key, other_key) }

    it_behaves_like 'reliable circuit breaker store method'

    context 'when keys exist' do
      before do
        circuit_store.store(key, value)
        circuit_store.store(other_key, other_value)
      end

      it 'returns values of keys' do
        expect(values_at).to match_array([value, other_value])
      end
    end

    context 'when some keys do not exist' do
      before do
        circuit_store.store(key, value)
      end

      it 'returns values of keys with nil for non-existing ones' do
        expect(values_at).to match_array([value, nil])
      end
    end
  end

  describe '#delete' do
    subject(:delete) { circuit_store.delete(key) }

    before do
      circuit_store.store(key, value)
    end

    it_behaves_like 'reliable circuit breaker store method'

    it 'deletes key' do
      delete

      with_redis do |redis|
        expect(redis.exists?(key)).to eq(false)
      end
    end
  end

  def with_redis(&block)
    Gitlab::Redis::RateLimiting.with(&block)
  end
end
