# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DeferJobs, feature_category: :scalability do
  let(:job) { { 'jid' => 123, 'args' => [456] } }
  let(:queue) { 'test_queue' }
  let(:test_worker) do
    Class.new do
      def self.name
        'TestWorker'
      end
      include ApplicationWorker
    end
  end

  subject { described_class.new }

  before do
    stub_const('TestWorker', test_worker)
  end

  describe '#call' do
    context 'with worker not opted for database health check' do
      context 'when run_sidekiq_jobs feature flag is disabled' do
        let(:deferred_jobs_metric) { instance_double(Prometheus::Client::Counter, increment: true) }

        before do
          stub_feature_flags(run_sidekiq_jobs_TestWorker: false)
          allow(Gitlab::Metrics).to receive(:counter).and_call_original
          allow(Gitlab::Metrics).to receive(:counter).with(described_class::DEFERRED_COUNTER, anything)
                                                     .and_return(deferred_jobs_metric)
        end

        it 'defers the job' do
          expect(TestWorker).to receive(:perform_in).with(described_class::DELAY, *job['args'])
          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.not_to yield_control
        end

        it 'increments the defer_count' do
          (1..5).each do |count|
            subject.call(TestWorker.new, job, queue)
            expect(job).to include('deferred_count' => count)
          end
        end

        it 'increments the counter' do
          expect(deferred_jobs_metric).to receive(:increment).with({ worker: "TestWorker" })

          subject.call(TestWorker.new, job, queue)
        end
      end

      context 'when run_sidekiq_jobs feature flag is enabled' do
        it 'runs the job normally' do
          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.to yield_control
        end
      end
    end

    context 'with worker opted for database health check' do
      let(:health_signal_attrs) { { gitlab_schema: :gitlab_main, delay: 1.minute, tables: [:users] } }

      around do |example|
        with_sidekiq_server_middleware do |chain|
          chain.add described_class
          Sidekiq::Testing.inline! { example.run }
        end
      end

      before do
        TestWorker.defer_on_database_health_signal(*health_signal_attrs.values)
      end

      context 'without any stop signal from database health check' do
        it 'runs the job normally' do
          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.to yield_control
        end
      end

      context 'with stop signal from database health check' do
        before do
          stop_signal = instance_double("Gitlab::Database::HealthStatus::Signals::Stop", stop?: true)
          allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])
        end

        it 'defers the job by set time' do
          expect(TestWorker).to receive(:perform_in).with(health_signal_attrs[:delay], *job['args'])

          TestWorker.perform_async(*job['args'])
        end
      end
    end
  end
end
