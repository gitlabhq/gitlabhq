# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::Store, :clean_gitlab_redis_rate_limiting, feature_category: :scalability do
  let(:store) { described_class.new }
  let(:key) { 'foobar' }
  let(:namespaced_key) { "cache:gitlab:#{key}" }

  def with_redis(&block)
    Gitlab::Redis::RateLimiting.with(&block)
  end

  describe '#increment' do
    it 'increments without expiry' do
      5.times do |i|
        expect(store.increment(key, 1)).to eq(i + 1)

        with_redis do |redis|
          expect(redis.get(namespaced_key).to_i).to eq(i + 1)
          expect(redis.ttl(namespaced_key)).to eq(-1)
        end
      end
    end

    it 'rejects amounts other than 1' do
      expect { store.increment(key, 2) }.to raise_exception(described_class::InvalidAmount)
    end

    context 'with expiry' do
      it 'increments and sets expiry' do
        5.times do |i|
          expect(store.increment(key, 1, expires_in: 456)).to eq(i + 1)

          with_redis do |redis|
            expect(redis.get(namespaced_key).to_i).to eq(i + 1)
            expect(redis.ttl(namespaced_key)).to be_within(10).of(456)
          end
        end
      end
    end
  end

  describe '#read' do
    subject { store.read(key) }

    it 'reads the namespaced key' do
      with_redis { |r| r.set(namespaced_key, '123') }

      expect(subject).to eq('123')
    end
  end

  describe '#write' do
    subject { store.write(key, '123', options) }

    let(:options) { {} }

    it 'sets the key' do
      subject

      with_redis do |redis|
        expect(redis.get(namespaced_key)).to eq('123')
        expect(redis.ttl(namespaced_key)).to eq(-1)
      end
    end

    context 'with expiry' do
      let(:options) { { expires_in: 456 } }

      it 'sets the key with expiry' do
        subject

        with_redis do |redis|
          expect(redis.get(namespaced_key)).to eq('123')
          expect(redis.ttl(namespaced_key)).to be_within(10).of(456)
        end
      end
    end
  end

  describe '#delete' do
    subject { store.delete(key) }

    it { expect(subject).to eq(0) }

    context 'when the key exists' do
      before do
        with_redis { |r| r.set(namespaced_key, '123') }
      end

      it { expect(subject).to eq(1) }
    end
  end

  describe '#with' do
    subject { store.send(:with, &:ping) }

    it { expect(subject).to eq('PONG') }

    context 'when redis is unavailable' do
      before do
        broken_redis = Redis.new(
          url: 'redis://127.0.0.0:0',
          custom: { instrumentation_class: Gitlab::Redis::RateLimiting.instrumentation_class }
        )
        allow(Gitlab::Redis::RateLimiting).to receive(:with).and_yield(broken_redis)
      end

      it { expect(subject).to eq(nil) }
    end
  end
end
