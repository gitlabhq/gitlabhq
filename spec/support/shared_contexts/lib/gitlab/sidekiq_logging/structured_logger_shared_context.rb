# frozen_string_literal: true

RSpec.shared_context 'structured_logger' do
  let(:timestamp) { Time.iso8601('2018-01-01T12:00:00.000Z') }
  let(:created_at) { timestamp - 1.second }
  let(:scheduling_latency_s) { 1.0 }

  let(:job) do
    {
      "class" => "TestWorker",
      "args" => [1234, 'hello', { 'key' => 'value' }],
      "retry" => false,
      "queue" => "cronjob:test_queue",
      "queue_namespace" => "cronjob",
      "jid" => "da883554ee4fe414012f5f42",
      "created_at" => created_at.to_f,
      "enqueued_at" => created_at.to_f,
      "correlation_id" => 'cid',
      "error_message" => "wrong number of arguments (2 for 3)",
      "error_class" => "ArgumentError",
      "error_backtrace" => []
    }
  end

  let(:logger) { double }
  let(:clock_realtime_start) { 0.222222299 }
  let(:clock_realtime_end) { 1.333333799 }
  let(:clock_thread_cputime_start) { 0.222222299 }
  let(:clock_thread_cputime_end) { 1.333333799 }
  let(:start_payload) do
    job.except('error_backtrace', 'error_class', 'error_message').merge(
      'message' => 'TestWorker JID-da883554ee4fe414012f5f42: start',
      'job_status' => 'start',
      'pid' => Process.pid,
      'created_at' => created_at.to_f,
      'enqueued_at' => created_at.to_f,
      'scheduling_latency_s' => scheduling_latency_s,
      'job_size_bytes' => be > 0
    )
  end

  let(:end_payload) do
    start_payload.merge(
      'message' => 'TestWorker JID-da883554ee4fe414012f5f42: done: 0.0 sec',
      'job_status' => 'done',
      'duration_s' => 0.0,
      'completed_at' => timestamp.to_f,
      'cpu_s' => 1.111112,
      'db_duration_s' => 0.0,
      'db_cached_count' => 0,
      'db_count' => 0,
      'db_write_count' => 0
    )
  end

  let(:exception_payload) do
    end_payload.merge(
      'message' => 'TestWorker JID-da883554ee4fe414012f5f42: fail: 0.0 sec',
      'job_status' => 'fail',
      'error_class' => 'ArgumentError',
      'error_message' => 'Something went wrong',
      'error_backtrace' => be_a(Array).and(be_present)
    )
  end

  before do
    allow(Sidekiq).to receive(:logger).and_return(logger)

    allow(subject).to receive(:current_time).and_return(timestamp.to_f)

    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_REALTIME, :float_second)
                        .and_return(clock_realtime_start, clock_realtime_end)
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_THREAD_CPUTIME_ID, :float_second)
                        .and_return(clock_thread_cputime_start, clock_thread_cputime_end)
  end

  subject { described_class.new }

  def call_subject(job, queue)
    # This structured logger strongly depends on execution of `InstrumentationLogger`
    subject.call(job, queue) do
      ::Gitlab::SidekiqMiddleware::InstrumentationLogger.new.call('worker', job, queue) do
        yield
      end
    end
  end
end
