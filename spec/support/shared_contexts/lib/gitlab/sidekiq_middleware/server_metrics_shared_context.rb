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
  let(:interrupted_total_metric) { double('interrupted total metric') }
  let(:redis_requests_total) { double('redis calls total metric') }
  let(:running_jobs_metric) { double('running jobs metric') }
  let(:redis_seconds_metric) { double('redis seconds metric') }
  let(:elasticsearch_seconds_metric) { double('elasticsearch seconds metric') }
  let(:elasticsearch_requests_total) { double('elasticsearch calls total metric') }
  let(:load_balancing_metric) { double('load balancing metric') }
  let(:sidekiq_mem_total_bytes) { double('sidekiq mem total bytes') }
  let(:completion_seconds_sum_metric) { double('sidekiq completion seconds sum metric') }
  let(:completion_count_metric) { double('sidekiq completion seconds count metric') }
  let(:cpu_seconds_sum_metric) { double('cpu seconds sum metric') }
  let(:db_seconds_sum_metric) { double('db seconds sum metric') }
  let(:gitaly_seconds_sum_metric) { double('gitaly seconds sum metric') }
  let(:redis_seconds_sum_metric) { double('redis seconds sum metric') }
  let(:elasticsearch_seconds_sum_metric) { double('elasticsearch seconds sum metric') }

  before do
    allow(Gitlab::Metrics).to receive(:histogram).and_call_original
    allow(Gitlab::Metrics).to receive(:counter).and_call_original

    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_queue_duration_seconds, anything, anything, anything).and_return(queue_duration_seconds)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_completion_seconds, anything, anything, anything).and_return(completion_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_cpu_seconds, anything, anything, anything).and_return(user_execution_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_db_seconds, anything, anything, anything).and_return(db_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_gitaly_seconds, anything, anything, anything).and_return(gitaly_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_redis_requests_duration_seconds, anything, anything, anything).and_return(redis_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_elasticsearch_requests_duration_seconds, anything, anything, anything).and_return(elasticsearch_seconds_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_failed_total, anything).and_return(failed_total_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_retried_total, anything).and_return(retried_total_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_interrupted_total, anything).and_return(interrupted_total_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_redis_requests_total, anything).and_return(redis_requests_total)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_elasticsearch_requests_total, anything).and_return(elasticsearch_requests_total)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_load_balancing_count, anything).and_return(load_balancing_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_completion_seconds_sum, anything).and_return(completion_seconds_sum_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_completion_count, anything).and_return(completion_count_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_cpu_seconds_sum, anything).and_return(cpu_seconds_sum_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_db_seconds_sum, anything).and_return(db_seconds_sum_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_gitaly_seconds_sum, anything).and_return(gitaly_seconds_sum_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_redis_requests_duration_seconds_sum, anything).and_return(redis_seconds_sum_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_elasticsearch_requests_duration_seconds_sum, anything).and_return(elasticsearch_seconds_sum_metric)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_running_jobs, anything, {}, :all).and_return(running_jobs_metric)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_concurrency, anything, {}, :all).and_return(concurrency_metric)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_mem_total_bytes, anything, {}, :all).and_return(sidekiq_mem_total_bytes)

    allow(concurrency_metric).to receive(:set)
    allow(completion_seconds_metric).to receive(:get)
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

  let(:mem_total_bytes) { 1000000000 }
  let(:instrumentation) do
    {
      gitaly_duration_s: gitaly_duration,
      redis_calls: redis_calls,
      redis_duration_s: redis_duration,
      elasticsearch_calls: elasticsearch_calls,
      elasticsearch_duration_s: elasticsearch_duration,
      mem_total_bytes: mem_total_bytes
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
    allow(completion_seconds_sum_metric).to receive(:increment)
    allow(completion_count_metric).to receive(:increment)
    allow(cpu_seconds_sum_metric).to receive(:increment)
    allow(db_seconds_sum_metric).to receive(:increment)
    allow(gitaly_seconds_sum_metric).to receive(:increment)
    allow(redis_seconds_sum_metric).to receive(:increment)
    allow(elasticsearch_seconds_sum_metric).to receive(:increment)
    allow(queue_duration_seconds).to receive(:observe)
    allow(user_execution_seconds_metric).to receive(:observe)
    allow(db_seconds_metric).to receive(:observe)
    allow(db_seconds_sum_metric).to receive(:increment)
    allow(gitaly_seconds_metric).to receive(:observe)
    allow(completion_seconds_metric).to receive(:observe)
    allow(redis_seconds_metric).to receive(:observe)
    allow(elasticsearch_seconds_metric).to receive(:observe)
    allow(sidekiq_mem_total_bytes).to receive(:set)
  end
end
