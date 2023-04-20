# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::SidekiqMiddleware::ServerMetrics do
  shared_examples "a metrics middleware" do
    context "with mocked prometheus" do
      include_context 'server metrics with mocked prometheus'

      describe '.initialize_process_metrics' do
        it 'sets concurrency metrics' do
          expect(concurrency_metric).to receive(:set).with({}, Sidekiq[:concurrency].to_i)

          described_class.initialize_process_metrics
        end

        it 'initializes sidekiq_jobs_completion_seconds for the workers in the current Sidekiq process' do
          allow(Gitlab::SidekiqConfig)
            .to receive(:current_worker_queue_mappings)
                  .and_return('MergeWorker' => 'merge', 'Ci::BuildFinishedWorker' => 'default')

          expect(completion_seconds_metric)
            .to receive(:get).with({ queue: 'merge',
                                     worker: 'MergeWorker',
                                     urgency: 'high',
                                     external_dependencies: 'no',
                                     feature_category: 'source_code_management',
                                     boundary: '',
                                     job_status: 'done' })

          expect(completion_seconds_metric)
            .to receive(:get).with({ queue: 'merge',
                                     worker: 'MergeWorker',
                                     urgency: 'high',
                                     external_dependencies: 'no',
                                     feature_category: 'source_code_management',
                                     boundary: '',
                                     job_status: 'fail' })

          expect(completion_seconds_metric)
            .to receive(:get).with({ queue: 'default',
                                     worker: 'Ci::BuildFinishedWorker',
                                     urgency: 'high',
                                     external_dependencies: 'no',
                                     feature_category: 'continuous_integration',
                                     boundary: 'cpu',
                                     job_status: 'done' })

          expect(completion_seconds_metric)
            .to receive(:get).with({ queue: 'default',
                                     worker: 'Ci::BuildFinishedWorker',
                                     urgency: 'high',
                                     external_dependencies: 'no',
                                     feature_category: 'continuous_integration',
                                     boundary: 'cpu',
                                     job_status: 'fail' })

          described_class.initialize_process_metrics
        end

        context 'when sidekiq_execution_application_slis FF is turned on' do
          it 'initializes sidekiq SLIs for the workers in the current Sidekiq process' do
            allow(Gitlab::SidekiqConfig)
              .to receive(:current_worker_queue_mappings)
                    .and_return('MergeWorker' => 'merge', 'Ci::BuildFinishedWorker' => 'default')

            allow(completion_seconds_metric).to receive(:get)

            expect(Gitlab::Metrics::SidekiqSlis)
              .to receive(:initialize_slis!).with([
                {
                  worker: 'MergeWorker',
                  urgency: 'high',
                  feature_category: 'source_code_management'
                },
                {
                  worker: 'Ci::BuildFinishedWorker',
                  urgency: 'high',
                  feature_category: 'continuous_integration'
                }
              ])

            described_class.initialize_process_metrics
          end
        end

        context 'when sidekiq_execution_application_slis FF is turned off' do
          before do
            stub_feature_flags(sidekiq_execution_application_slis: false)
          end

          it 'does not initialize sidekiq SLIs' do
            expect(Gitlab::Metrics::SidekiqSlis)
              .not_to receive(:initialize_slis!)

            described_class.initialize_process_metrics
          end
        end

        context 'when the sidekiq_job_completion_metric_initialize feature flag is disabled' do
          before do
            stub_feature_flags(sidekiq_job_completion_metric_initialize: false)
          end

          it 'sets the concurrency metric' do
            expect(concurrency_metric).to receive(:set).with({}, Sidekiq[:concurrency].to_i)

            described_class.initialize_process_metrics
          end

          it 'does not initialize sidekiq_jobs_completion_seconds' do
            allow(Gitlab::SidekiqConfig)
              .to receive(:current_worker_queue_mappings)
                    .and_return('MergeWorker' => 'merge', 'Ci::BuildFinishedWorker' => 'default')

            expect(completion_seconds_metric).not_to receive(:get)

            described_class.initialize_process_metrics
          end

          it 'does not initializes sidekiq SLIs' do
            allow(Gitlab::SidekiqConfig)
              .to receive(:current_worker_queue_mappings)
                    .and_return('MergeWorker' => 'merge', 'Ci::BuildFinishedWorker' => 'default')

            expect(Gitlab::Metrics::SidekiqSlis)
              .not_to receive(:initialize_slis!)

            described_class.initialize_process_metrics
          end
        end
      end

      describe '#call' do
        include_context 'server metrics call'

        it 'yields block' do
          expect { |b| subject.call(worker, job, :test, &b) }.to yield_control.once
        end

        it 'calls BackgroundTransaction' do
          expect_next_instance_of(Gitlab::Metrics::BackgroundTransaction) do |instance|
            expect(instance).to receive(:run)
          end

          subject.call(worker, job, :test) {}
        end

        it 'sets queue specific metrics' do
          expect(running_jobs_metric).to receive(:increment).with(labels, -1)
          expect(running_jobs_metric).to receive(:increment).with(labels, 1)
          expect(queue_duration_seconds).to receive(:observe).with(labels, queue_duration_for_job) if queue_duration_for_job
          expect(user_execution_seconds_metric).to receive(:observe).with(labels_with_job_status, thread_cputime_duration)
          expect(db_seconds_metric).to receive(:observe).with(labels_with_job_status, db_duration)
          expect(gitaly_seconds_metric).to receive(:observe).with(labels_with_job_status, gitaly_duration)
          expect(completion_seconds_metric).to receive(:observe).with(labels_with_job_status, monotonic_time_duration)
          expect(redis_seconds_metric).to receive(:observe).with(labels_with_job_status, redis_duration)
          expect(elasticsearch_seconds_metric).to receive(:observe).with(labels_with_job_status, elasticsearch_duration)
          expect(redis_requests_total).to receive(:increment).with(labels_with_job_status, redis_calls)
          expect(elasticsearch_requests_total).to receive(:increment).with(labels_with_job_status, elasticsearch_calls)
          expect(sidekiq_mem_total_bytes).to receive(:set).with(labels_with_job_status, mem_total_bytes)
          expect(Gitlab::Metrics::SidekiqSlis).to receive(:record_execution_apdex).with(labels.slice(:worker,
            :feature_category,
            :urgency), monotonic_time_duration)
          expect(Gitlab::Metrics::SidekiqSlis).to receive(:record_execution_error).with(labels.slice(:worker,
            :feature_category,
            :urgency), false)

          subject.call(worker, job, :test) { nil }
        end

        it 'sets sidekiq_jobs_completion_seconds values that are compatible with those from .initialize_process_metrics' do
          label_validator = Prometheus::Client::LabelSetValidator.new([:le])

          allow(Gitlab::SidekiqConfig)
            .to receive(:current_worker_queue_mappings)
                  .and_return('MergeWorker' => 'merge', 'Ci::BuildFinishedWorker' => 'default')

          allow(completion_seconds_metric).to receive(:get) do |labels|
            expect { label_validator.validate(labels) }.not_to raise_error
          end

          allow(completion_seconds_metric).to receive(:observe) do |labels, _duration|
            expect { label_validator.validate(labels) }.not_to raise_error
          end

          described_class.initialize_process_metrics

          subject.call(worker, job, :test) { nil }
        end

        it 'sets the thread name if it was nil' do
          allow(Thread.current).to receive(:name).and_return(nil)
          expect(Thread.current).to receive(:name=).with(Gitlab::Metrics::Samplers::ThreadsSampler::SIDEKIQ_WORKER_THREAD_NAME)

          subject.call(worker, job, :test) { nil }
        end

        context 'when job_duration is not available' do
          let(:queue_duration_for_job) { nil }

          it 'does not set the queue_duration_seconds histogram' do
            expect(queue_duration_seconds).not_to receive(:observe)

            subject.call(worker, job, :test) { nil }
          end
        end

        context 'when error is raised' do
          let(:job_status) { :fail }

          it 'sets sidekiq_jobs_failed_total and reraises' do
            expect(failed_total_metric).to receive(:increment).with(labels, 1)

            expect { subject.call(worker, job, :test) { raise StandardError, "Failed" } }.to raise_error(StandardError, "Failed")
          end

          it 'records sidekiq SLI error but does not record sidekiq SLI apdex' do
            expect(failed_total_metric).to receive(:increment)
            expect(Gitlab::Metrics::SidekiqSlis).not_to receive(:record_execution_apdex)
            expect(Gitlab::Metrics::SidekiqSlis).to receive(:record_execution_error).with(labels.slice(:worker,
              :feature_category,
              :urgency), true)

            expect { subject.call(worker, job, :test) { raise StandardError, "Failed" } }.to raise_error(StandardError, "Failed")
          end
        end

        context 'when job is retried' do
          let(:job) { { 'retry_count' => 1 } }

          it 'sets sidekiq_jobs_retried_total metric' do
            expect(retried_total_metric).to receive(:increment)

            subject.call(worker, job, :test) { nil }
          end
        end

        context 'when job is interrupted' do
          let(:job) { { 'interrupted_count' => 1 } }

          it 'sets sidekiq_jobs_interrupted_total metric' do
            expect(interrupted_total_metric).to receive(:increment)

            subject.call(worker, job, :test) { nil }
          end
        end

        context 'when sidekiq_execution_application_slis FF is turned off' do
          before do
            stub_feature_flags(sidekiq_execution_application_slis: false)
          end

          it 'does not call record_execution_apdex nor record_execution_error' do
            expect(Gitlab::Metrics::SidekiqSlis).not_to receive(:record_execution_apdex)
            expect(Gitlab::Metrics::SidekiqSlis).not_to receive(:record_execution_error)

            subject.call(worker, job, :test) { nil }
          end
        end
      end
    end

    context "with prometheus integrated" do
      describe '#call' do
        it 'yields block' do
          expect { |b| subject.call(worker, job, :test, &b) }.to yield_control.once
        end

        context 'when error is raised' do
          let(:job_status) { :fail }

          it 'sets sidekiq_jobs_failed_total and reraises' do
            expect { subject.call(worker, job, :test) { raise StandardError, "Failed" } }.to raise_error(StandardError, "Failed")
          end
        end
      end
    end
  end

  it_behaves_like 'metrics middleware with worker attribution' do
    let(:job_status) { :done }
    let(:labels_with_job_status) { labels.merge(job_status: job_status.to_s) }
  end

  context 'DB load balancing' do
    subject { described_class.new }

    let(:queue) { :test }
    let(:worker_class) { worker.class }
    let(:worker) { TestWorker.new }
    let(:client_middleware) { Gitlab::Database::LoadBalancing::SidekiqClientMiddleware.new }
    let(:load_balancer) { double.as_null_object }
    let(:load_balancing_metric) { double('load balancing metric') }
    let(:job) { { "retry" => 3, "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e" } }

    def process_job
      client_middleware.call(worker_class, job, queue, double) do
        worker_class.process_job(job)
      end
    end

    include_context 'server metrics with mocked prometheus'
    include_context 'server metrics call'

    before do
      stub_const('TestWorker', Class.new)
      TestWorker.class_eval do
        include Sidekiq::Worker
        include WorkerAttributes

        def perform(*args); end
      end

      allow(::Gitlab::Database::LoadBalancing).to receive_message_chain(:proxy, :load_balancer).and_return(load_balancer)
      allow(load_balancing_metric).to receive(:increment)
      allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_load_balancing_count, anything).and_return(load_balancing_metric)
    end

    around do |example|
      with_sidekiq_server_middleware do |chain|
        chain.add Gitlab::Database::LoadBalancing::SidekiqServerMiddleware
        chain.add described_class
        Sidekiq::Testing.inline! { example.run }
      end
    end

    shared_context 'worker declaring data consistency' do
      let(:worker_class) { LBTestWorker }
      let(:wal_locations) { { Gitlab::Database::MAIN_DATABASE_NAME.to_sym => 'AB/12345' } }
      let(:job) { { "retry" => 3, "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", "wal_locations" => wal_locations } }

      before do
        stub_const('LBTestWorker', Class.new(TestWorker))
        LBTestWorker.class_eval do
          include ApplicationWorker

          data_consistency :delayed
        end
      end
    end

    describe '#call' do
      context 'when worker declares data consistency' do
        include_context 'worker declaring data consistency'

        it 'increments load balancing counter with defined data consistency' do
          process_job

          expect(load_balancing_metric).to have_received(:increment).with(
            a_hash_including(
              data_consistency: :delayed,
              load_balancing_strategy: 'replica'
            ), 1)
        end
      end

      context 'when worker does not declare data consistency' do
        it 'increments load balancing counter with default data consistency' do
          process_job

          expect(load_balancing_metric).to have_received(:increment).with(
            a_hash_including(
              data_consistency: :always,
              load_balancing_strategy: 'primary'
            ), 1)
        end
      end
    end
  end

  context 'feature attribution' do
    let(:test_worker) do
      category = worker_category

      Class.new do
        include Sidekiq::Worker
        include WorkerAttributes

        if category
          feature_category category
        else
          feature_category :not_owned
        end

        def perform; end
      end
    end

    let(:context_category) { 'continuous_integration' }
    let(:job) { { 'meta.feature_category' => 'continuous_integration' } }

    before do
      stub_const('TestWorker', test_worker)
    end

    around do |example|
      with_sidekiq_server_middleware do |chain|
        Gitlab::SidekiqMiddleware.server_configurator(
          metrics: true,
          arguments_logger: false
        ).call(chain)

        Sidekiq::Testing.inline! { example.run }
      end
    end

    include_context 'server metrics with mocked prometheus'
    include_context 'server metrics call'

    context 'when a worker has a feature category' do
      let(:worker_category) { 'system_access' }

      it 'uses that category for metrics' do
        expect(completion_seconds_metric).to receive(:observe).with(a_hash_including(feature_category: worker_category), anything)

        TestWorker.process_job(job)
      end
    end

    context 'when a worker does not have a feature category' do
      let(:worker_category) { nil }

      it 'uses the category from the context for metrics' do
        expect(completion_seconds_metric).to receive(:observe).with(a_hash_including(feature_category: context_category), anything)

        TestWorker.process_job(job)
      end
    end
  end
end
# rubocop: enable RSpec/MultipleMemoizedHelpers
