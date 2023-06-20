# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DeferJobs, feature_category: :scalability do
  let(:job) { { 'jid' => 123, 'args' => [456] } }
  let(:queue) { 'test_queue' }
  let(:deferred_worker) do
    Class.new do
      def self.name
        'TestDeferredWorker'
      end
      include ApplicationWorker
    end
  end

  let(:undeferred_worker) do
    Class.new do
      def self.name
        'UndeferredWorker'
      end
      include ApplicationWorker
    end
  end

  subject { described_class.new }

  before do
    stub_const('TestDeferredWorker', deferred_worker)
    stub_const('UndeferredWorker', undeferred_worker)
  end

  describe '#call' do
    context 'with worker not opted for database health check' do
      context 'when sidekiq_defer_jobs feature flag is enabled for a worker' do
        before do
          stub_feature_flags("defer_sidekiq_jobs_#{TestDeferredWorker.name}": true)
          stub_feature_flags("defer_sidekiq_jobs_#{UndeferredWorker.name}": false)
        end

        context 'for the affected worker' do
          it 'defers the job' do
            expect(TestDeferredWorker).to receive(:perform_in).with(described_class::DELAY, *job['args'])
            expect { |b| subject.call(TestDeferredWorker.new, job, queue, &b) }.not_to yield_control
          end
        end

        context 'for other workers' do
          it 'runs the job normally' do
            expect { |b| subject.call(UndeferredWorker.new, job, queue, &b) }.to yield_control
          end
        end

        it 'increments the counter' do
          subject.call(TestDeferredWorker.new, job, queue)

          counter = ::Gitlab::Metrics.registry.get(:sidekiq_jobs_deferred_total)
          expect(counter.get({ worker: "TestDeferredWorker" })).to eq(1)
        end
      end

      context 'when sidekiq_defer_jobs feature flag is disabled' do
        before do
          stub_feature_flags("defer_sidekiq_jobs_#{TestDeferredWorker.name}": false)
          stub_feature_flags("defer_sidekiq_jobs_#{UndeferredWorker.name}": false)
        end

        it 'runs the job normally' do
          expect { |b| subject.call(TestDeferredWorker.new, job, queue, &b) }.to yield_control
          expect { |b| subject.call(UndeferredWorker.new, job, queue, &b) }.to yield_control
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
        stub_feature_flags("defer_sidekiq_jobs_#{TestDeferredWorker.name}": false)

        TestDeferredWorker.defer_on_database_health_signal(*health_signal_attrs.values)
      end

      context 'without any stop signal from database health check' do
        it 'runs the job normally' do
          expect { |b| subject.call(TestDeferredWorker.new, job, queue, &b) }.to yield_control
        end
      end

      context 'with stop signal from database health check' do
        before do
          stop_signal = instance_double("Gitlab::Database::HealthStatus::Signals::Stop", stop?: true)
          allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])
        end

        it 'defers the job by set time' do
          expect(TestDeferredWorker).to receive(:perform_in).with(health_signal_attrs[:delay], *job['args'])

          TestDeferredWorker.perform_async(*job['args'])
        end
      end
    end
  end
end
