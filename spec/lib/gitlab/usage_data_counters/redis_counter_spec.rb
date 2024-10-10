# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::RedisCounter, :clean_gitlab_redis_shared_state,
  feature_category: :application_instrumentation do
  let(:redis_key) { 'foobar' }

  subject { Class.new.extend(described_class) }

  describe '.increment' do
    it 'counter is increased' do
      expect do
        subject.increment(redis_key)
      end.to change { subject.total_count(redis_key) }.by(1)
    end

    it 'does not have an expiration timestamp' do
      subject.increment(redis_key)

      expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(-1)
    end

    context 'for every aliased legacy key' do
      let(:key_overrides) { YAML.safe_load(File.read(described_class::KEY_OVERRIDES_PATH)) }

      it 'counter is increased for a legacy key' do
        key_overrides.each do |alias_key, legacy_key|
          expect { subject.increment(alias_key) }.to change { subject.total_count(legacy_key) }.by(1),
            "Incrementing #{alias_key} did not increase #{legacy_key}"
        end
      end
    end

    context 'when expiry is passed as an argument' do
      let(:expiry) { 7.days }

      it 'counter is increased' do
        expect do
          subject.increment(redis_key, expiry: 7.days)
        end.to change { subject.total_count(redis_key) }.by(1)
      end

      it 'adds an expiration timestamp to the key' do
        subject.increment(redis_key, expiry: 7.days)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to be > 0
      end

      it 'does not reset the expiration timestamp when counter is increased again' do
        subject.increment(redis_key, expiry: 7.days)

        expiry = Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }

        subject.increment(redis_key, expiry: 14.days)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(expiry)
      end
    end
  end

  describe '.increment_by' do
    it 'counter is increased' do
      expect do
        subject.increment_by(redis_key, 3)
      end.to change { subject.total_count(redis_key) }.by(3)
    end

    it 'does not have an expiration timestamp' do
      subject.increment_by(redis_key, 3)

      expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(-1)
    end

    context 'when expiry is passed as an argument' do
      let(:expiry) { 7.days }

      it 'counter is increased' do
        expect do
          subject.increment_by(redis_key, 3, expiry: 7.days)
        end.to change { subject.total_count(redis_key) }.by(3)
      end

      it 'adds an expiration timestamp to the key' do
        subject.increment_by(redis_key, 3, expiry: 7.days)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to be > 0
      end

      it 'does not reset the expiration timestamp when counter is increased again' do
        subject.increment_by(redis_key, 3, expiry: 7.days)

        expiry = Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }

        subject.increment_by(redis_key, 3, expiry: 14.days)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }).to eq(expiry)
      end
    end
  end

  describe '.with_batched_redis_writes' do
    context 'when batch mode is active' do
      it 'accumulates increments without immediately updating Redis' do
        subject.with_batched_redis_writes do
          expect do
            subject.increment(redis_key)
            subject.increment_by(redis_key, 2)
          end.to not_change { subject.total_count(redis_key) }

          expect(Thread.current[:redis_counter_batch_key_count][redis_key]).to be(3)
        end
      end

      it 'applies accumulated increments after the block' do
        expect do
          subject.with_batched_redis_writes do
            subject.increment(redis_key)
            subject.increment_by(redis_key, 2)
          end
        end.to change { subject.total_count(redis_key) }.by(3)
      end

      it 'ensures that batch mode is cleaned up' do
        subject.with_batched_redis_writes do
          subject.increment(redis_key)
        end

        expect(Thread.current[:redis_counter_batch_mode]).to be_falsey
        expect(Thread.current[:redis_counter_batch_key_count]).to be_nil
        expect(Thread.current[:redis_counter_batch_expires]).to be_nil
      end

      it 'handles expiry' do
        expiry_time = 7.days

        subject.with_batched_redis_writes do
          subject.increment(redis_key, expiry: expiry_time)
        end

        ttl = Gitlab::Redis::SharedState.with { |redis| redis.ttl(redis_key) }

        expect(ttl).to be > 0
        expect(ttl).to be <= expiry_time
      end
    end

    context 'when an exception occurs within the block' do
      it 'ensures that batch mode is cleaned up' do
        expect do
          subject.with_batched_redis_writes do
            subject.increment(redis_key)
            raise StandardError
          end
        end.to raise_error(StandardError)

        expect(Thread.current[:redis_counter_batch_mode]).to be_falsey
        expect(Thread.current[:redis_counter_batch_key_count]).to be_nil
        expect(Thread.current[:redis_counter_batch_expires]).to be_nil
      end

      it 'flushes pending increments before the exception is raised' do
        expect do
          subject.with_batched_redis_writes do
            subject.increment(redis_key)
            raise StandardError
          end
        end.to raise_error(StandardError)
          .and change { subject.total_count(redis_key) }.by(1)
      end
    end

    context 'when batch mode is not active' do
      it 'increments counters immediately' do
        expect do
          subject.increment(redis_key)
        end.to change { subject.total_count(redis_key) }.by(1)
      end

      it 'does not accumulate increments' do
        subject.increment(redis_key)
        expect(Thread.current[:redis_counter_batch_key_count]).to be_nil
      end
    end
  end
end
