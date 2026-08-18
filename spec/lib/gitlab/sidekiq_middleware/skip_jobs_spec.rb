# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SkipJobs, feature_category: :scalability do
  let(:job) { { 'jid' => 123, 'args' => [456] } }
  let(:queue) { 'test_queue' }
  let(:setter) { instance_double('Sidekiq::Job::Setter') }
  let(:worker) do
    Class.new do
      def self.name
        'TestWorker'
      end
      include ApplicationWorker

      feature_category :scalability
    end
  end

  subject { described_class.new }

  before do
    stub_const('TestWorker', worker)
    stub_feature_flags("drop_sidekiq_jobs_#{TestWorker.name}": false)
  end

  describe '#call' do
    context 'with worker not opted for database health check' do
      let(:metric) { instance_double(Prometheus::Client::Counter, increment: true) }

      shared_examples 'runs the job normally' do
        it 'yields control' do
          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.to yield_control
        end

        it 'does not increment any metric counter' do
          expect(metric).not_to receive(:increment)

          subject.call(TestWorker.new, job, queue) { nil }
        end

        it 'does not increment deferred_count' do
          subject.call(TestWorker.new, job, queue) { nil }

          expect(job).not_to include('deferred_count')
        end

        context 'when deferred jobs are re-enabled' do
          let(:job) { { 'deferred' => true, 'args' => [456], 'jid' => 123 } }

          it 'does not have the deferred key in job hash' do
            subject.call(TestWorker.new, job, queue) { nil }

            expect(job).not_to include('deferred')
          end
        end
      end

      shared_examples 'drops the job' do
        it 'does not yield control' do
          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.not_to yield_control
        end

        it 'increments counter' do
          expect(metric).to receive(:increment).with({
            worker: "TestWorker",
            action: "dropped",
            reason: "feature_flag",
            feature_category: "scalability"
          })

          subject.call(TestWorker.new, job, queue) { nil }
        end

        it 'does not increment deferred_count' do
          subject.call(TestWorker.new, job, queue) { nil }

          expect(job).not_to include('deferred_count')
        end

        it 'has dropped field in job equal to true' do
          subject.call(TestWorker.new, job, queue) { nil }

          expect(job).to include({ 'dropped' => true })
        end
      end

      shared_examples 'defers the job' do
        it 'does not yield control' do
          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.not_to yield_control
        end

        it 'delays the job' do
          expect(TestWorker).to receive(:deferred).with(1, :feature_flag).and_return(setter)
          expect(setter).to receive(:set).with(jid: job['jid']).and_return(setter)
          expect(setter).to receive(:perform_in).with(described_class::DELAY, *job['args'])

          subject.call(TestWorker.new, job, queue) { nil }
        end

        it 'increments counter' do
          expect(metric).to receive(:increment).with({
            worker: "TestWorker",
            action: "deferred",
            reason: "feature_flag",
            feature_category: "scalability"
          })

          subject.call(TestWorker.new, job, queue) { nil }
        end

        it 'has deferred related fields in job payload' do
          subject.call(TestWorker.new, job, queue) { nil }

          expect(job).to include({ 'deferred' => true, 'deferred_by' => :feature_flag, 'deferred_count' => 1 })
        end
      end

      describe "with all combinations of drop and defer FFs" do
        using RSpec::Parameterized::TableSyntax

        before do
          stub_feature_flags("drop_sidekiq_jobs_#{TestWorker.name}": drop_ff)
          stub_feature_flags("run_sidekiq_jobs_#{TestWorker.name}": run_ff)
          allow(Gitlab::Metrics).to receive(:counter).and_call_original
          allow(Gitlab::Metrics).to receive(:counter).with(described_class::COUNTER, anything).and_return(metric)
        end

        where(:drop_ff, :run_ff, :resulting_behavior) do
          false | true  | "runs the job normally"
          true  | true  | "drops the job"
          false | false | "defers the job"
          true  | false | "drops the job"
        end

        with_them do
          it_behaves_like params[:resulting_behavior]
        end
      end

      describe 'using current_request actor', :request_store do
        before do
          allow(Gitlab::Metrics).to receive(:counter).and_call_original
          allow(Gitlab::Metrics).to receive(:counter).with(described_class::COUNTER, anything).and_return(metric)
        end

        context 'with drop_sidekiq_jobs FF' do
          before do
            stub_feature_flags("drop_sidekiq_jobs_#{TestWorker.name}": Feature.current_request)
          end

          it_behaves_like 'drops the job'

          context 'for different request' do
            before do
              stub_with_new_feature_current_request
            end

            it_behaves_like 'runs the job normally'
          end
        end

        context 'with run_sidekiq_jobs FF' do
          before do
            stub_feature_flags("run_sidekiq_jobs_#{TestWorker.name}": Feature.current_request)
          end

          it_behaves_like 'runs the job normally'

          context 'for different request' do
            before do
              stub_with_new_feature_current_request
            end

            it_behaves_like 'defers the job'
          end
        end
      end
    end

    context 'with worker opted for database health check' do
      let(:health_signal_attrs) { { gitlab_schema: :gitlab_main, tables: [:users], delay_by: 1.minute } }

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
        let(:metric) { instance_double(Prometheus::Client::Counter, increment: true) }

        before do
          stop_signal = instance_double("Gitlab::Database::HealthStatus::Signals::Stop", stop?: true)
          allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])
          allow(Gitlab::Metrics).to receive(:counter).and_call_original
          allow(Gitlab::Metrics).to receive(:counter).with(described_class::COUNTER, anything).and_return(metric)
        end

        it 'defers the job by set time' do
          expect(TestWorker).to receive(:deferred).with(1, :database_health_check).and_return(setter)
          expect(setter).to receive(:set).with(jid: anything).and_return(setter)
          expect(setter).to receive(:perform_in).with(health_signal_attrs[:delay_by], *job['args'])

          TestWorker.perform_async(*job['args'])
        end

        it 'increments counter' do
          expect(TestWorker).to receive(:deferred).with(1, :database_health_check).and_return(setter)
          expect(setter).to receive(:set).with(jid: anything).and_return(setter)
          expect(setter).to receive(:perform_in).with(health_signal_attrs[:delay_by], *job['args'])
          expect(metric).to receive(:increment).with({
            worker: "TestWorker",
            action: "deferred",
            reason: "database_health_check",
            feature_category: "scalability"
          })

          TestWorker.perform_async(*job['args'])
        end

        context 'when the job has already been deferred by the database health check' do
          using RSpec::Parameterized::TableSyntax

          let(:job) { { 'jid' => 123, 'args' => [456], 'deferred_count' => deferred_count } }

          before do
            allow(subject).to receive(:rand).and_return(0)
          end

          # delay_by is 1 minute, set by the health_signal_attrs fixture. deferred_count is the
          # pre-increment value from the job hash;
          # defer_job! increments it before computing the delay, so the first row is the job's
          # second deferral. Each consecutive deferral doubles the delay, capped at 30 minutes.
          where(:deferred_count, :expected_delay) do
            1  | 2.minutes.to_i
            2  | 4.minutes.to_i
            4  | 16.minutes.to_i
            5  | 30.minutes.to_i
            50 | 30.minutes.to_i
          end

          with_them do
            it 'defers the job with exponential backoff' do
              expect(TestWorker).to receive(:deferred).with(deferred_count + 1, :database_health_check)
                .and_return(setter)
              expect(setter).to receive(:set).with(jid: job['jid']).and_return(setter)
              expect(setter).to receive(:perform_in).with(expected_delay, *job['args'])

              subject.call(TestWorker.new, job, queue) { nil }
            end
          end
        end

        context 'with jitter' do
          let(:job) { { 'jid' => 123, 'args' => [456], 'deferred_count' => 50 } }

          it 'subtracts up to 10% of the capped delay so the cap is a hard ceiling' do
            expect(subject).to receive(:rand).with((30.minutes.to_i / 10) + 1).and_return(42)

            expect(TestWorker).to receive(:deferred).with(51, :database_health_check).and_return(setter)
            expect(setter).to receive(:set).with(jid: job['jid']).and_return(setter)
            expect(setter).to receive(:perform_in).with(30.minutes.to_i - 42, *job['args'])

            subject.call(TestWorker.new, job, queue) { nil }
          end
        end

        context 'when the job was previously deferred by the feature flag' do
          let(:job) do
            { 'jid' => 123, 'args' => [456], 'deferred_count' => 3, 'deferred_by' => 'feature_flag' }
          end

          it 'backs off from the shared deferred_count' do
            allow(subject).to receive(:rand).and_return(0)

            expect(TestWorker).to receive(:deferred).with(4, :database_health_check).and_return(setter)
            expect(setter).to receive(:set).with(jid: job['jid']).and_return(setter)
            expect(setter).to receive(:perform_in).with(8.minutes.to_i, *job['args'])

            subject.call(TestWorker.new, job, queue) { nil }
          end
        end

        context 'when incremental_database_health_defer_delay is disabled' do
          let(:job) { { 'jid' => 123, 'args' => [456], 'deferred_count' => 5 } }

          before do
            stub_feature_flags(incremental_database_health_defer_delay: false)
          end

          it 'defers the job by the fixed delay_by' do
            expect(TestWorker).to receive(:deferred).with(6, :database_health_check).and_return(setter)
            expect(setter).to receive(:set).with(jid: job['jid']).and_return(setter)
            expect(setter).to receive(:perform_in).with(health_signal_attrs[:delay_by], *job['args'])

            subject.call(TestWorker.new, job, queue) { nil }
          end
        end

        context 'when the job is deferred by the run_sidekiq_jobs feature flag' do
          let(:job) { { 'jid' => 123, 'args' => [456], 'deferred_count' => 3 } }

          before do
            stub_feature_flags("run_sidekiq_jobs_#{TestWorker.name}": false)
          end

          it 'uses the fixed delay regardless of deferred_count' do
            expect(TestWorker).to receive(:deferred).with(4, :feature_flag).and_return(setter)
            expect(setter).to receive(:set).with(jid: job['jid']).and_return(setter)
            expect(setter).to receive(:perform_in).with(described_class::DELAY, *job['args'])

            subject.call(TestWorker.new, job, queue) { nil }
          end
        end
      end

      context 'when a block is provided' do
        before do
          TestWorker.defer_on_database_health_signal(*health_signal_attrs.values) do
            [:gitlab_ci, [:ci_pipelines]]
          end
        end

        it 'uses the lazy evaluated schema and tables returned by the block' do
          expect(Gitlab::Database::HealthStatus::Context).to receive(:new)
            .with(anything, anything, [:ci_pipelines]).and_call_original

          expect { |b| subject.call(TestWorker.new, job, queue, &b) }.to yield_control
        end
      end
    end
  end
end
