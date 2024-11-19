# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ConcurrencyLimitSampler, feature_category: :scalability do
  let(:workers_with_limits) { [Import::ReassignPlaceholderUserRecordsWorker] * 5 }

  subject(:sample) { described_class.new.sample }

  it_behaves_like 'metrics sampler', 'CONCURRENCY_LIMIT_SAMPLER'

  describe '#sample' do
    before do
      allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap)
          .to receive(:workers).and_return(workers_with_limits)
    end

    it 'fetches data for each worker and sets counter' do
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap)
          .to receive(:workers).and_return(workers_with_limits)

      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .to receive(:queue_size).exactly(workers_with_limits.size).times.and_return(1)
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:concurrent_worker_count).exactly(workers_with_limits.size).times.and_return(1)

      queue_size_gauge_double = instance_double(Prometheus::Client::Counter)
      expect(Gitlab::Metrics).to receive(:counter)
        .once
        .with(:sidekiq_concurrency_limit_queue_jobs_total, anything)
        .and_return(queue_size_gauge_double)
      expect(queue_size_gauge_double).to receive(:increment)
        .with({ worker: anything }, anything)
        .exactly(workers_with_limits.size).times

      concurrency_gauge_double = instance_double(Prometheus::Client::Counter)
      expect(Gitlab::Metrics).to receive(:counter)
        .once
        .with(:sidekiq_concurrency_limit_current_concurrent_jobs_total, anything)
        .and_return(concurrency_gauge_double)
      expect(concurrency_gauge_double).to receive(:increment)
        .with({ worker: anything }, anything)
        .exactly(workers_with_limits.size).times

      sample
    end

    it 'fetches data for each worker and skips setting counter on empty data' do
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap)
          .to receive(:workers).and_return(workers_with_limits)

      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .to receive(:queue_size).exactly(workers_with_limits.size).times.and_return(0)
      expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:concurrent_worker_count).exactly(workers_with_limits.size).times.and_return(0)

      expect(Gitlab::Metrics).not_to receive(:counter)

      sample
    end
  end
end
