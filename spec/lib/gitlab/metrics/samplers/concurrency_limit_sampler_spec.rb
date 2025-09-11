# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ConcurrencyLimitSampler, :clean_gitlab_redis_shared_state,
  feature_category: :scalability do
  include ExclusiveLeaseHelpers
  let(:worker_class) { ::Import::ReassignPlaceholderUserRecordsWorker }
  let(:lease_key) { 'gitlab/metrics/samplers/concurrency_limit_sampler:queues:default' }
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
        allow(sampler.exclusive_lease).to receive(:same_uuid?).and_return(true, false) # run sample once
      end

      context 'for current queue workers' do
        before do
          allow(Gitlab::SidekiqConfig).to receive(:workers_without_default).and_return(
            [Gitlab::SidekiqConfig::Worker.new(worker_class, ee: false)]
          )
        end

        it 'fetches data for each worker and sets gauge' do
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
            .to receive(:queue_size).once.and_return(1)
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
            .to receive(:concurrent_worker_count).once.and_return(1)
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
            .to receive(:current_limit).once.and_return(1)

          queue_size_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_queue_jobs, anything)
                                       .and_return(queue_size_gauge_double)
          expect(queue_size_gauge_double).to receive(:set)
                                               .with({ worker: worker_class.name, feature_category: anything }, 1)
                                               .once
          expect(queue_size_gauge_double).to receive(:set)
                                               .with({ worker: worker_class.name, feature_category: anything }, 0)
                                               .once

          concurrency_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_current_concurrent_jobs, anything)
                                       .and_return(concurrency_gauge_double)
          expect(concurrency_gauge_double).to receive(:set)
                                                .with({ worker: anything, feature_category: anything }, 1)
                                                .once
          expect(concurrency_gauge_double).to receive(:set)
                                                .with({ worker: worker_class.name, feature_category: anything }, 0)
                                                .once

          limit_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_max_concurrent_jobs, anything)
                                       .and_return(limit_gauge_double)
          expect(limit_gauge_double).to receive(:set)
                                          .with({ worker: worker_class.name, feature_category: anything },
                                            worker_class.get_concurrency_limit)
                                          .once
          expect(limit_gauge_double).to receive(:set)
                                          .with({ worker: worker_class.name, feature_category: anything }, 0)
                                          .once

          current_limit_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_current_limit, anything)
                                       .and_return(current_limit_gauge_double)
          expect(current_limit_gauge_double).to receive(:set)
                                                  .with({ worker: worker_class.name, feature_category: anything }, 1)
                                                  .once
          expect(current_limit_gauge_double).to receive(:set)
                                                  .with({ worker: worker_class.name, feature_category: anything }, 0)
                                                  .once

          sample
        end
      end

      context 'for workers outside of current queue' do
        let(:test_worker) do
          Class.new do
            def self.name
              'TestWorker'
            end

            include ApplicationWorker

            def perform(*_args); end
          end
        end

        before do
          # Stub the list of currently defined workers
          allow(Gitlab::SidekiqConfig).to receive(:workers_without_default).and_return(
            [
              Gitlab::SidekiqConfig::Worker.new(test_worker, ee: false),
              Gitlab::SidekiqConfig::Worker.new(worker_class, ee: false)
            ]
          )

          # Stub the routing so that test_worker is routed to another queue (test_queue)
          # and the current_queue only consists of worker_class
          allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route)
                                                                   .with(test_worker)
                                                                   .and_return('test_queue')
          allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route)
                                                                   .with(worker_class)
                                                                   .and_return('current_queue')

          # Stub the sidekiq queues to return current_queue
          allow(Sidekiq.default_configuration).to receive(:queues).and_return(['current_queue'])
        end

        it 'does not report metrics for test_worker' do
          queue_size_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_queue_jobs, anything)
                                       .and_return(queue_size_gauge_double)
          expect(queue_size_gauge_double).not_to receive(:set)
                                               .with({ worker: test_worker.name, feature_category: anything }, anything)

          concurrency_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_current_concurrent_jobs, anything)
                                       .and_return(concurrency_gauge_double)
          expect(concurrency_gauge_double).not_to receive(:set)
                                                .with({ worker: test_worker.name, feature_category: anything },
                                                  anything)

          limit_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_max_concurrent_jobs, anything)
                                       .and_return(limit_gauge_double)
          expect(limit_gauge_double).not_to receive(:set)
                                          .with({ worker: test_worker.name, feature_category: anything }, anything)

          current_limit_gauge_double = instance_double(Prometheus::Client::Gauge)
          expect(Gitlab::Metrics).to receive(:gauge)
                                       .once
                                       .with(:sidekiq_concurrency_limit_current_limit, anything)
                                       .and_return(current_limit_gauge_double)
          expect(current_limit_gauge_double).not_to receive(:set)
                                                  .with({ worker: test_worker.name, feature_category: anything },
                                                    anything)

          sample
        end
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
