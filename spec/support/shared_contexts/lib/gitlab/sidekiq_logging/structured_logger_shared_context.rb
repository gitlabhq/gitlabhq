# frozen_string_literal: true

RSpec.shared_context 'structured_logger' do
  let(:timestamp) { Time.iso8601('2018-01-01T12:00:00.000Z') }
  let(:created_at) { timestamp - 1.second }
  let(:scheduling_latency_s) { 1.0 }
  let(:queue_duration_s) { 1.0 }
  let(:worker_class) { "TestWorker" }

  let(:job) do
    {
      "class" => worker_class,
      "args" => [1234, 'hello', { 'key' => 'value' }],
      "retry" => false,
      "queue" => "cronjob:test_queue",
      "queue_namespace" => "cronjob",
      "jid" => "da883554ee4fe414012f5f42",
      "created_at" => created_at.to_f,
      "enqueued_at" => created_at.to_f,
      "correlation_id" => 'cid',
      "exception.message" => "wrong number of arguments (2 for 3)",
      "exception.class" => "ArgumentError",
      "exception.backtrace" => []
    }
  end

  let(:logger) { double }
  let(:clock_realtime_start) { 0.222222299 }
  let(:clock_realtime_end) { 1.333333799 }
  let(:clock_thread_cputime_start) { 0.222222299 }
  let(:clock_thread_cputime_end) { 1.333333799 }
  let(:start_payload) do
    job.except(
      'exception.backtrace', 'exception.class', 'exception.message'
    ).merge(
      'message' => "#{worker_class} JID-da883554ee4fe414012f5f42: start",
      'job_status' => 'start',
      'pid' => Process.pid,
      'created_at' => created_at.to_f,
      'enqueued_at' => created_at.to_f,
      'scheduling_latency_s' => scheduling_latency_s,
      'queue_duration_s' => queue_duration_s,
      'job_size_bytes' => be > 0,
      'sidekiq_tid' => be_instance_of(String)
    )
  end

  let(:db_payload_defaults) do
    metrics =
      ::Gitlab::Metrics::Subscribers::ActiveRecord.load_balancing_metric_counter_keys +
      ::Gitlab::Metrics::Subscribers::ActiveRecord.load_balancing_metric_duration_keys +
      [:db_duration_s]

    metrics.each_with_object({}) do |key, result|
      result[key.to_s] = 0
    end
  end

  let(:end_payload) do
    start_payload.merge(db_payload_defaults).merge(
      'message' => "#{worker_class} JID-da883554ee4fe414012f5f42: done: 0.0 sec",
      'job_status' => 'done',
      'duration_s' => 0.0,
      'completed_at' => timestamp.to_f,
      'cpu_s' => 1.111112,
      'rate_limiting_gates' => [],
      'worker_id' => "process_#{Process.pid}"
    )
  end

  let(:deferred_payload) do
    end_payload.merge(
      'message' => "#{worker_class} JID-da883554ee4fe414012f5f42: deferred: 0.0 sec",
      'job_status' => 'deferred',
      'job_deferred_by' => :feature_flag,
      'deferred_count' => 1
    )
  end

  let(:dropped_payload) do
    end_payload.merge(
      'message' => 'TestWorker JID-da883554ee4fe414012f5f42: dropped: 0.0 sec',
      'job_status' => 'dropped'
    )
  end

  let(:exception_payload) do
    end_payload.merge(
      'message' => "#{worker_class} JID-da883554ee4fe414012f5f42: fail: 0.0 sec",
      'job_status' => 'fail',
      'exception.class' => 'ArgumentError',
      'exception.message' => 'Something went wrong',
      'exception.backtrace' => be_a(Array).and(be_present)
    )
  end

  before do
    allow(subject).to receive(:current_time).and_return(timestamp.to_f)

    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_REALTIME, :float_second)
                        .and_return(clock_realtime_start, clock_realtime_end)
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_THREAD_CPUTIME_ID, :float_second)
                        .and_return(clock_thread_cputime_start, clock_thread_cputime_end)
    allow(Process).to receive(:clock_gettime).with(anything, :float_millisecond).and_call_original
  end

  subject { described_class.new(logger) }

  def call_subject(job, queue)
    # This structured logger strongly depends on execution of `InstrumentationLogger`
    subject.call(job, queue) do
      ::Gitlab::SidekiqMiddleware::InstrumentationLogger.new.call('worker', job, queue) do
        yield
      end
    end
  end
end
