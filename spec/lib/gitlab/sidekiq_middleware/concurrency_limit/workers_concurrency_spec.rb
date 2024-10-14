# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestConcurrencyLimitWorker'
      end

      include ApplicationWorker

      concurrency_limit -> { 60 }

      def perform(*); end
    end
  end

  let(:current_concurrency) { 10 }
  let(:work) do
    instance_double(Sidekiq::Work, payload: { 'class' => 'TestConcurrencyLimitWorker' }.to_json, queue: 'default')
  end

  let(:sidekiq_worker) do
    [
      'process_id',
      'thread_id',
      work
    ]
  end

  before do
    stub_const('TestConcurrencyLimitWorker', worker_class)
    allow(described_class).to receive(:sidekiq_workers).and_return([sidekiq_worker] * current_concurrency)
  end

  describe '.current_for' do
    subject(:current_for) { described_class.current_for(worker: TestConcurrencyLimitWorker, skip_cache: skip_cache) }

    context 'without cache' do
      let(:skip_cache) { true }

      it 'returns the current concurrency', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/451677' do
        expect(described_class).to receive(:workers_uncached).and_call_original
        expect(current_for).to eq(current_concurrency)
      end
    end

    context 'with cache', :clean_gitlab_redis_cache do
      let(:skip_cache) { false }
      let(:cached_value) { { "TestConcurrencyLimitWorker" => 20 } }

      before do
        cache_setup!(tally: cached_value, lease: true)
      end

      it 'returns cached current_for' do
        expect(described_class).not_to receive(:workers_uncached)

        expect(current_for).to eq(20)
      end
    end
  end

  describe '.workers' do
    subject(:workers) { described_class.workers(skip_cache: skip_cache) }

    context 'without cache' do
      let(:skip_cache) { true }

      it 'returns current_workers', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463861' do
        expect(workers).to eq('TestConcurrencyLimitWorker' => 10)
      end

      context 'with multiple shard instances' do
        before do
          allow(Gitlab::Redis::Queues)
              .to receive(:instances).and_return({ 'main' => Gitlab::Redis::Queues, 'shard' => Gitlab::Redis::Queues })
        end

        it 'returns count for all instances' do
          expect(workers).to eq({
            'TestConcurrencyLimitWorker' => current_concurrency * Gitlab::Redis::Queues.instances.size
          })
        end
      end
    end

    context 'with cache', :clean_gitlab_redis_cache do
      let(:skip_cache) { false }
      let(:cached_value) { { "TestConcurrencyLimitWorker" => 20 } }
      let(:actual_tally) { { "TestConcurrencyLimitWorker" => 15 } }

      before do
        cache_setup!(tally: cached_value, lease: lease)
      end

      context 'when lease is not held by another process' do
        let(:lease) { false }

        it 'returns the current concurrency' do
          expect(described_class).to receive(:workers_uncached).and_return(actual_tally)

          expect(workers).to eq(actual_tally)
        end
      end

      context 'when lease is held by another process' do
        let(:lease) { true }

        it 'returns cached workers' do
          expect(described_class).not_to receive(:workers_uncached)

          expect(workers).to eq(cached_value)
        end
      end

      context 'when lease is held by another process but the cache is empty' do
        let(:lease) { true }
        let(:cached_value) { nil }

        it 'returns the current concurrency' do
          expect(described_class).to receive(:workers_uncached).and_return(actual_tally)

          expect(workers).to eq(actual_tally)
        end
      end
    end
  end

  def cache_setup!(tally:, lease:)
    Gitlab::Redis::Cache.with do |redis|
      if tally
        redis.set(described_class::CACHE_KEY, tally.to_json)
      else
        redis.del(described_class::CACHE_KEY)
      end

      if lease
        redis.set(described_class::LEASE_KEY, 1)
      else
        redis.del(described_class::LEASE_KEY)
      end
    end
  end
end
