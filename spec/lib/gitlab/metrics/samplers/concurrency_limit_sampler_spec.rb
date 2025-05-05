# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ConcurrencyLimitSampler, :clean_gitlab_redis_shared_state,
  feature_category: :scalability do
  include ExclusiveLeaseHelpers
  let(:workers_with_limits) { [Import::ReassignPlaceholderUserRecordsWorker] * 5 }
  let(:lease_key) { 'gitlab/metrics/samplers/concurrency_limit_sampler' }
  let(:sampler) { described_class.new }

  subject(:sample) { sampler.sample }

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
        .with({ worker: anything, feature_category: anything }, anything)
        .exactly(workers_with_limits.size).times

      concurrency_gauge_double = instance_double(Prometheus::Client::Counter)
      expect(Gitlab::Metrics).to receive(:counter)
        .once
        .with(:sidekiq_concurrency_limit_current_concurrent_jobs_total, anything)
        .and_return(concurrency_gauge_double)
      expect(concurrency_gauge_double).to receive(:increment)
        .with({ worker: anything, feature_category: anything }, anything)
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

    context 'when lease can be obtained' do
      before do
        stub_exclusive_lease(lease_key, timeout: described_class::DEFAULT_SAMPLING_INTERVAL_SECONDS)
      end

      it 'calls concurrent_limit_service methods' do
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:queue_size)
          .exactly(workers_with_limits.size)
          .and_call_original
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:concurrent_worker_count)
          .exactly(workers_with_limits.size)
          .and_call_original

        sample
      end

      it 'does not release the lease' do
        sample

        expect(sampler.exclusive_lease.exists?).to be_truthy
      end
    end

    context 'when exclusive lease cannot be obtained' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_SAMPLING_INTERVAL_SECONDS)
      end

      it 'does not call concurrent_limit_service' do
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).not_to receive(:queue_size)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .not_to receive(:concurrent_worker_count)

        sample
      end
    end
  end
end
