# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Throttling::Tracker, :clean_gitlab_redis_queues_metadata,
  feature_category: :scalability do
  let(:worker_name) { 'TestWorker' }

  subject(:tracker) { described_class.new(worker_name) }

  describe '.throttled_workers' do
    let(:redis_key) { 'sidekiq:throttling:worker:lookup:throttled' }

    before do
      Gitlab::Redis::QueuesMetadata.with do |redis|
        redis.sadd(redis_key, 'WorkerA')
        redis.sadd(redis_key, 'WorkerB')
      end
    end

    it 'returns a list of currently throttled workers' do
      expect(described_class.throttled_workers).to contain_exactly('WorkerA', 'WorkerB')
    end
  end

  describe '#record' do
    let(:period_key) { Time.current.to_i.divmod(60).first }
    let(:cache_key) { "sidekiq:throttling:worker:{#{worker_name}}:#{period_key}:throttled" }
    let(:lookup_key) { 'sidekiq:throttling:worker:lookup:throttled' }

    it 'records the worker as throttled in Redis' do
      tracker.record

      Gitlab::Redis::QueuesMetadata.with do |redis|
        expect(redis.exists?(cache_key)).to be true
        expect(redis.sismember(lookup_key, worker_name)).to be true
      end
    end

    it 'sets an expiry on the cache key' do
      tracker.record

      Gitlab::Redis::QueuesMetadata.with do |redis|
        expect(redis.ttl(cache_key)).to be_within(5).of(Gitlab::SidekiqMiddleware::Throttling::Tracker::TTL)
      end
    end

    it 'sets an expiry on the lookup key' do
      tracker.record

      Gitlab::Redis::QueuesMetadata.with do |redis|
        expect(redis.ttl(lookup_key)).to be_within(5).of(Gitlab::SidekiqMiddleware::Throttling::Tracker::LOOKUP_KEY_TTL)
      end
    end
  end

  describe '#currently_throttled?' do
    let(:period_key) { Time.current.to_i.divmod(60).first }
    let(:cache_key) { "sidekiq:throttling:worker:{#{worker_name}}:#{period_key}:throttled" }

    context 'when worker was throttled' do
      before do
        Gitlab::Redis::QueuesMetadata.with do |redis|
          redis.set(cache_key, 'true', ex: described_class::TTL)
        end
      end

      context 'when throttled in the current minute' do
        it 'returns true' do
          expect(tracker.currently_throttled?).to be true
        end
      end

      context 'when throttled in the previous minute' do
        let(:period_key) { (Time.current - 1.minute).to_i.divmod(60).first }

        it 'returns false' do
          expect(tracker.currently_throttled?).to be false
        end
      end
    end

    context 'when the worker is not currently throttled' do
      it 'returns false' do
        expect(tracker.currently_throttled?).to be false
      end
    end
  end
end
