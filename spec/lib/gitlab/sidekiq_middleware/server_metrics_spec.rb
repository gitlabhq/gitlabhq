# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::SidekiqMiddleware::ServerMetrics do
  shared_examples "a metrics middleware" do
    context "with mocked prometheus" do
      include_context 'server metrics with mocked prometheus'

      describe '#initialize' do
        it 'sets concurrency metrics' do
          expect(concurrency_metric).to receive(:set).with({}, Sidekiq.options[:concurrency].to_i)

          subject
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
        end

        context 'when job is retried' do
          let(:job) { { 'retry_count' => 1 } }

          it 'sets sidekiq_jobs_retried_total metric' do
            expect(retried_total_metric).to receive(:increment)

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
end
# rubocop: enable RSpec/MultipleMemoizedHelpers
