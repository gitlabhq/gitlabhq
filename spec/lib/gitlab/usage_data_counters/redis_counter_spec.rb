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
end
