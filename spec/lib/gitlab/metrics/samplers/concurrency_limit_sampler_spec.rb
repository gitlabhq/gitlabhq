# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ConcurrencyLimitSampler, :clean_gitlab_redis_shared_state,
  feature_category: :scalability do
  include ExclusiveLeaseHelpers
  let(:workers_with_limits) { [Import::ReassignPlaceholderUserRecordsWorker] * 5 }
  let(:lease_key) { 'gitlab/metrics/samplers/concurrency_limit_sampler' }
  let(:sampler) { described_class.new }

  subject(:sample) { sampler.sample }

  before do
    allow(Kernel).to receive(:sleep)
  end

  it_behaves_like 'metrics sampler', 'CONCURRENCY_LIMIT_SAMPLER'

  describe '#sample' do
    before do
      allow(sampler).to receive(:running).and_return(true)
    end

    context 'when lease can be obtained' do
      before do
        allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap)
          .to receive(:workers).and_return(workers_with_limits)
        allow(sampler.exclusive_lease).to receive(:same_uuid?).and_return(true, false) # run sample once
      end

      it 'fetches data for each worker and sets gauge' do
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap)
            .to receive(:workers).and_return(workers_with_limits)

        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .to receive(:queue_size).exactly(workers_with_limits.size).times.and_return(1)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
            .to receive(:concurrent_worker_count).exactly(workers_with_limits.size).times.and_return(1)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap)
          .to receive(:limit_for).exactly(workers_with_limits.size).times.and_return(1)

        queue_size_gauge_double = instance_double(Prometheus::Client::Gauge)
        expect(Gitlab::Metrics).to receive(:gauge)
          .once
          .with(:sidekiq_concurrency_limit_queue_jobs, anything)
          .and_return(queue_size_gauge_double)
        expect(queue_size_gauge_double).to receive(:set)
          .with({ worker: anything, feature_category: anything }, 1)
          .exactly(workers_with_limits.size).times
        expect(queue_size_gauge_double).to receive(:set)
                                             .with({ worker: anything, feature_category: anything }, 0)
                                             .exactly(workers_with_limits.size).times

        concurrency_gauge_double = instance_double(Prometheus::Client::Gauge)
        expect(Gitlab::Metrics).to receive(:gauge)
          .once
          .with(:sidekiq_concurrency_limit_current_concurrent_jobs, anything)
          .and_return(concurrency_gauge_double)
        expect(concurrency_gauge_double).to receive(:set)
          .with({ worker: anything, feature_category: anything }, 1)
          .exactly(workers_with_limits.size).times
        expect(concurrency_gauge_double).to receive(:set)
                                              .with({ worker: anything, feature_category: anything }, 0)
                                              .exactly(workers_with_limits.size).times

        limit_gauge_double = instance_double(Prometheus::Client::Gauge)
        expect(Gitlab::Metrics).to receive(:gauge)
                                     .once
                                     .with(:sidekiq_concurrency_limit_max_concurrent_jobs, anything)
                                     .and_return(limit_gauge_double)
        expect(limit_gauge_double).to receive(:set)
                                              .with({ worker: anything, feature_category: anything }, 1)
                                              .exactly(workers_with_limits.size).times
        expect(limit_gauge_double).to receive(:set)
                                              .with({ worker: anything, feature_category: anything }, 0)
                                              .exactly(workers_with_limits.size).times

        sample
      end

      context 'when lease exists for more than 1 cycle' do
        before do
          allow(sampler.exclusive_lease).to receive(:same_uuid?).and_return(true, true, true, false)
        end

        it 'report metrics while lease exists and afterwards reset the metrics' do
          expect(sampler).to receive(:report_metrics).exactly(3).times
          expect(Kernel).to receive(:sleep).exactly(3).times
          expect(sampler).to receive(:reset_metrics).once

          sample
        end
      end

      context 'when sampler thread stops running' do
        before do
          allow(sampler).to receive(:running).and_return(true, true, false)
          allow(sampler.exclusive_lease).to receive(:same_uuid?).and_return(true)
        end

        it 'reports metrics once and resets the metrics' do
          expect(sampler).to receive(:report_metrics).once
          expect(Kernel).to receive(:sleep).once
          expect(sampler).to receive(:reset_metrics).once

          sample
        end
      end
    end

    context 'when lease cannot be obtained' do
      before do
        stub_exclusive_lease_taken(lease_key)
      end

      it 'does not report anything' do
        expect(sampler).not_to receive(:report_metrics)
        expect(Kernel).not_to receive(:sleep)
        expect(sampler).not_to receive(:reset_metrics)

        sample
      end
    end
  end
end
