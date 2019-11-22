# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::SidekiqMiddleware::Metrics do
  context "with worker attribution" do
    subject { described_class.new }

    let(:queue) { :test }
    let(:worker_class) { worker.class }
    let(:job) { {} }
    let(:job_status) { :done }
    let(:labels_with_job_status) { labels.merge(job_status: job_status.to_s) }
    let(:default_labels) { { queue: queue.to_s, boundary: "", external_dependencies: "no", feature_category: "", latency_sensitive: "no" } }

    shared_examples "a metrics middleware" do
      context "with mocked prometheus" do
        let(:concurrency_metric) { double('concurrency metric') }

        let(:queue_duration_seconds) { double('queue duration seconds metric') }
        let(:completion_seconds_metric) { double('completion seconds metric') }
        let(:user_execution_seconds_metric) { double('user execution seconds metric') }
        let(:failed_total_metric) { double('failed total metric') }
        let(:retried_total_metric) { double('retried total metric') }
        let(:running_jobs_metric) { double('running jobs metric') }

        before do
          allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_queue_duration_seconds, anything, anything, anything).and_return(queue_duration_seconds)
          allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_completion_seconds, anything, anything, anything).and_return(completion_seconds_metric)
          allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_cpu_seconds, anything, anything, anything).and_return(user_execution_seconds_metric)
          allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_failed_total, anything).and_return(failed_total_metric)
          allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_retried_total, anything).and_return(retried_total_metric)
          allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_running_jobs, anything, {}, :all).and_return(running_jobs_metric)
          allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_concurrency, anything, {}, :all).and_return(concurrency_metric)

          allow(concurrency_metric).to receive(:set)
        end

        describe '#initialize' do
          it 'sets concurrency metrics' do
            expect(concurrency_metric).to receive(:set).with({}, Sidekiq.options[:concurrency].to_i)

            subject
          end
        end

        describe '#call' do
          let(:thread_cputime_before) { 1 }
          let(:thread_cputime_after) { 2 }
          let(:thread_cputime_duration) { thread_cputime_after - thread_cputime_before }

          let(:monotonic_time_before) { 11 }
          let(:monotonic_time_after) { 20 }
          let(:monotonic_time_duration) { monotonic_time_after - monotonic_time_before }

          let(:queue_duration_for_job) { 0.01 }

          before do
            allow(subject).to receive(:get_thread_cputime).and_return(thread_cputime_before, thread_cputime_after)
            allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(monotonic_time_before, monotonic_time_after)
            allow(Gitlab::InstrumentationHelper).to receive(:queue_duration_for_job).with(job).and_return(queue_duration_for_job)

            expect(running_jobs_metric).to receive(:increment).with(labels, 1)
            expect(running_jobs_metric).to receive(:increment).with(labels, -1)

            expect(queue_duration_seconds).to receive(:observe).with(labels, queue_duration_for_job) if queue_duration_for_job
            expect(user_execution_seconds_metric).to receive(:observe).with(labels_with_job_status, thread_cputime_duration)
            expect(completion_seconds_metric).to receive(:observe).with(labels_with_job_status, monotonic_time_duration)
          end

          it 'yields block' do
            expect { |b| subject.call(worker, job, :test, &b) }.to yield_control.once
          end

          it 'sets queue specific metrics' do
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

    context "when workers are not attributed" do
      class TestNonAttributedWorker
        include Sidekiq::Worker
      end
      let(:worker) { TestNonAttributedWorker.new }
      let(:labels) { default_labels }

      it_behaves_like "a metrics middleware"
    end

    context "when workers are attributed" do
      def create_attributed_worker_class(latency_sensitive, external_dependencies, resource_boundary, category)
        Class.new do
          include Sidekiq::Worker
          include WorkerAttributes

          latency_sensitive_worker! if latency_sensitive
          worker_has_external_dependencies! if external_dependencies
          worker_resource_boundary resource_boundary unless resource_boundary == :unknown
          feature_category category unless category.nil?
        end
      end

      let(:latency_sensitive) { false }
      let(:external_dependencies) { false }
      let(:resource_boundary) { :unknown }
      let(:feature_category) { nil }
      let(:worker_class) { create_attributed_worker_class(latency_sensitive, external_dependencies, resource_boundary, feature_category) }
      let(:worker) { worker_class.new }

      context "latency sensitive" do
        let(:latency_sensitive) { true }
        let(:labels) { default_labels.merge(latency_sensitive: "yes") }

        it_behaves_like "a metrics middleware"
      end

      context "external dependencies" do
        let(:external_dependencies) { true }
        let(:labels) { default_labels.merge(external_dependencies: "yes") }

        it_behaves_like "a metrics middleware"
      end

      context "cpu boundary" do
        let(:resource_boundary) { :cpu }
        let(:labels) { default_labels.merge(boundary: "cpu") }

        it_behaves_like "a metrics middleware"
      end

      context "memory boundary" do
        let(:resource_boundary) { :memory }
        let(:labels) { default_labels.merge(boundary: "memory") }

        it_behaves_like "a metrics middleware"
      end

      context "feature category" do
        let(:feature_category) { :authentication }
        let(:labels) { default_labels.merge(feature_category: "authentication") }

        it_behaves_like "a metrics middleware"
      end

      context "combined" do
        let(:latency_sensitive) { true }
        let(:external_dependencies) { true }
        let(:resource_boundary) { :cpu }
        let(:feature_category) { :authentication }
        let(:labels) { default_labels.merge(latency_sensitive: "yes", external_dependencies: "yes", boundary: "cpu", feature_category: "authentication") }

        it_behaves_like "a metrics middleware"
      end
    end
  end
end
