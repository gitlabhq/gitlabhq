# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Cookie, :clean_gitlab_redis_shared_state,
:clean_gitlab_redis_queues do
  describe 'serialization' do
    it 'can round-trip a hash' do
      h = { 'hello' => 'world', 'foo' => 'bar' }
      expect(described_class.deserialize(described_class.serialize(h))).to eq(h)
    end

    it 'can merge by concatenating' do
      h1 = { 'foo' => 'bar', 'baz' => 'qux' }
      h2 = { 'foo' => 'other bar', 'hello' => 'world' }
      concatenated = described_class.serialize(h1) + described_class.serialize(h2)
      expect(described_class.deserialize(concatenated)).to eq(h1.merge(h2))
    end
  end

  shared_examples 'with Redis persistence' do
    let(:cookie) { described_class.new(key) }
    let(:key) { 'redis_key' }
    let(:hash) { { 'hello' => 'world' } }

    describe '.set' do
      subject { cookie.set(hash, expiry) }

      let(:expiry) { 10 }

      it 'stores the hash' do
        expect(subject).to be_truthy
        with_redis do |redis|
          expect(redis.get(key)).to eq("hello=world\n")
          expect(redis.ttl(key)).to be_within(1).of(expiry)
        end
      end

      context 'when the key is set' do
        before do
          with_redis { |r| r.set(key, 'foobar') }
        end

        it 'does not overwrite existing keys' do
          expect(subject).to be_falsey
          with_redis do |redis|
            expect(redis.get(key)).to eq('foobar')
            expect(redis.ttl(key)).to eq(-1)
          end
        end
      end
    end

    describe '.get' do
      subject { cookie.get }

      it { expect(subject).to eq({}) }

      context 'when the key is set' do
        before do
          with_redis { |r| r.set(key, "hello=world\n") }
        end

        it { expect(subject).to eq({ 'hello' => 'world' }) }
      end
    end

    describe '.append' do
      subject { cookie.append(hash) }

      it 'does not create the key' do
        subject

        with_redis do |redis|
          expect(redis.get(key)).to eq(nil)
        end
      end

      context 'when the key exists' do
        before do
          with_redis { |r| r.set(key, 'existing data', ex: 10) }
        end

        it 'appends without modifying ttl' do
          subject

          with_redis do |redis|
            expect(redis.get(key)).to eq("existing datahello=world\n")
            expect(redis.ttl(key)).to be_within(1).of(10)
          end
        end
      end
    end
  end

  context 'with multi-store feature flags turned on' do
    def with_redis(&block)
      Gitlab::Redis::DuplicateJobs.with(&block)
    end

    it 'use Gitlab::Redis::DuplicateJobs.with' do
      expect(Gitlab::Redis::DuplicateJobs).to receive(:with).and_call_original
      expect(Sidekiq).not_to receive(:redis)

      described_class.new('hello').get
    end

    it_behaves_like 'with Redis persistence'
  end

  context 'when both multi-store feature flags are off' do
    def with_redis(&block)
      Sidekiq.redis(&block)
    end

    before do
      stub_feature_flags(use_primary_and_secondary_stores_for_duplicate_jobs: false)
      stub_feature_flags(use_primary_store_as_default_for_duplicate_jobs: false)
    end

    it 'use Sidekiq.redis' do
      expect(Sidekiq).to receive(:redis).and_call_original
      expect(Gitlab::Redis::DuplicateJobs).not_to receive(:with)

      described_class.new('hello').get
    end

    it_behaves_like 'with Redis persistence'
  end
end
