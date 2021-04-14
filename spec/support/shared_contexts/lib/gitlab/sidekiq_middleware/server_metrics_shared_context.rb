# frozen_string_literal: true

RSpec.shared_context 'server metrics with mocked prometheus' do
  let(:concurrency_metric) { double('concurrency metric') }

  let(:queue_duration_seconds) { double('queue duration seconds metric') }
  let(:completion_seconds_metric) { double('completion seconds metric') }
  let(:user_execution_seconds_metric) { double('user execution seconds metric') }
  let(:db_seconds_metric) { double('db seconds metric') }
  let(:gitaly_seconds_metric) { double('gitaly seconds metric') }
  let(:failed_total_metric) { double('failed total metric') }
  let(:retried_total_metric) { double('retried total metric') }
  let(:redis_requests_total) { double('redis calls total metric') }
  let(:running_jobs_metric) { double('running jobs metric') }
  let(:redis_seconds_metric) { double('redis seconds metric') }
  let(:elasticsearch_seconds_metric) { double('elasticsearch seconds metric') }
  let(:elasticsearch_requests_total) { double('elasticsearch calls total metric') }

  before do
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_queue_duration_seconds, anything, anything, anything).and_return(queue_duration_seconds)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_completion_seconds, anything, anything, anything).and_return(completion_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_cpu_seconds, anything, anything, anything).and_return(user_execution_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_db_seconds, anything, anything, anything).and_return(db_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_gitaly_seconds, anything, anything, anything).and_return(gitaly_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_redis_requests_duration_seconds, anything, anything, anything).and_return(redis_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_elasticsearch_requests_duration_seconds, anything, anything, anything).and_return(elasticsearch_seconds_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_failed_total, anything).and_return(failed_total_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_retried_total, anything).and_return(retried_total_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_redis_requests_total, anything).and_return(redis_requests_total)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_elasticsearch_requests_total, anything).and_return(elasticsearch_requests_total)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_running_jobs, anything, {}, :all).and_return(running_jobs_metric)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_concurrency, anything, {}, :all).and_return(concurrency_metric)

    allow(concurrency_metric).to receive(:set)
  end
end

RSpec.shared_context 'server metrics call' do
  let(:thread_cputime_before) { 1 }
  let(:thread_cputime_after) { 2 }
  let(:thread_cputime_duration) { thread_cputime_after - thread_cputime_before }

  let(:monotonic_time_before) { 11 }
  let(:monotonic_time_after) { 20 }
  let(:monotonic_time_duration) { monotonic_time_after - monotonic_time_before }

  let(:queue_duration_for_job) { 0.01 }

  let(:db_duration) { 3 }
  let(:gitaly_duration) { 4 }

  let(:redis_calls) { 2 }
  let(:redis_duration) { 0.01 }

  let(:elasticsearch_calls) { 8 }
  let(:elasticsearch_duration) { 0.54 }
  let(:instrumentation) do
    {
      gitaly_duration_s: gitaly_duration,
      redis_calls: redis_calls,
      redis_duration_s: redis_duration,
      elasticsearch_calls: elasticsearch_calls,
      elasticsearch_duration_s: elasticsearch_duration
    }
  end

  before do
    allow(subject).to receive(:get_thread_cputime).and_return(thread_cputime_before, thread_cputime_after)
    allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(monotonic_time_before, monotonic_time_after)
    allow(Gitlab::InstrumentationHelper).to receive(:queue_duration_for_job).with(job).and_return(queue_duration_for_job)
    allow(ActiveRecord::LogSubscriber).to receive(:runtime).and_return(db_duration * 1000)

    job[:instrumentation] = instrumentation
    job[:gitaly_duration_s] = gitaly_duration
    job[:redis_calls] = redis_calls
    job[:redis_duration_s] = redis_duration

    job[:elasticsearch_calls] = elasticsearch_calls
    job[:elasticsearch_duration_s] = elasticsearch_duration

    allow(running_jobs_metric).to receive(:increment)
    allow(redis_requests_total).to receive(:increment)
    allow(elasticsearch_requests_total).to receive(:increment)
    allow(queue_duration_seconds).to receive(:observe)
    allow(user_execution_seconds_metric).to receive(:observe)
    allow(db_seconds_metric).to receive(:observe)
    allow(gitaly_seconds_metric).to receive(:observe)
    allow(completion_seconds_metric).to receive(:observe)
    allow(redis_seconds_metric).to receive(:observe)
    allow(elasticsearch_seconds_metric).to receive(:observe)
  end
end
