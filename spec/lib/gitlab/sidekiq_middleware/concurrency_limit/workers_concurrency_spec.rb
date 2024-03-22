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
  let(:sidekiq_worker) do
    [
      'process_id',
      'thread_id',
      {
        'queue' => 'default',
        'payload' => {
          'class' => 'TestConcurrencyLimitWorker'
        }.to_json
      }
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

      it 'returns the current concurrency' do
        expect(described_class).to receive(:workers_uncached).and_call_original
        expect(current_for).to eq(current_concurrency)
      end
    end

    context 'with cache' do
      let(:skip_cache) { false }
      let(:cached_value) { { "TestConcurrencyLimitWorker" => 20 } }

      before do
        allow(Rails.cache).to receive(:fetch).and_return(cached_value)
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

      it 'returns current_workers' do
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

    context 'with cache' do
      let(:skip_cache) { false }
      let(:cached_value) { { "TestConcurrencyLimitWorker" => 20 } }

      before do
        allow(Rails.cache).to receive(:fetch).and_return(cached_value)
      end

      it 'returns cached workers' do
        expect(described_class).not_to receive(:workers_uncached)

        expect(workers).to eq(cached_value)
      end
    end
  end
end
