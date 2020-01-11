# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqLogging::StructuredLogger do
  describe '#call' do
    let(:timestamp) { Time.iso8601('2018-01-01T12:00:00.000Z') }
    let(:created_at) { timestamp - 1.second }
    let(:scheduling_latency_s) { 1.0 }

    let(:job) do
      {
        "class" => "TestWorker",
        "args" => [1234, 'hello'],
        "retry" => false,
        "queue" => "cronjob:test_queue",
        "queue_namespace" => "cronjob",
        "jid" => "da883554ee4fe414012f5f42",
        "created_at" => created_at.to_f,
        "enqueued_at" => created_at.to_f,
        "correlation_id" => 'cid'
      }
    end

    let(:logger) { double }
    let(:clock_thread_cputime_start) { 0.222222299 }
    let(:clock_thread_cputime_end) { 1.333333799 }
    let(:start_payload) do
      job.merge(
        'message' => 'TestWorker JID-da883554ee4fe414012f5f42: start',
        'job_status' => 'start',
        'pid' => Process.pid,
        'created_at' => created_at.to_f,
        'enqueued_at' => created_at.to_f,
        'scheduling_latency_s' => scheduling_latency_s
      )
    end
    let(:end_payload) do
      start_payload.merge(
        'message' => 'TestWorker JID-da883554ee4fe414012f5f42: done: 0.0 sec',
        'job_status' => 'done',
        'duration' => 0.0,
        'completed_at' => timestamp.to_f,
        'cpu_s' => 1.111112,
        'db_duration' => 0,
        'db_duration_s' => 0
      )
    end
    let(:exception_payload) do
      end_payload.merge(
        'message' => 'TestWorker JID-da883554ee4fe414012f5f42: fail: 0.0 sec',
        'job_status' => 'fail',
        'error_class' => 'ArgumentError',
        'error_message' => 'some exception'
      )
    end

    before do
      allow(Sidekiq).to receive(:logger).and_return(logger)

      allow(subject).to receive(:current_time).and_return(timestamp.to_f)

      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_THREAD_CPUTIME_ID).and_return(clock_thread_cputime_start, clock_thread_cputime_end)
    end

    subject { described_class.new }

    context 'with SIDEKIQ_LOG_ARGUMENTS enabled' do
      before do
        stub_env('SIDEKIQ_LOG_ARGUMENTS', '1')
      end

      it 'logs start and end of job' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload).ordered
          expect(logger).to receive(:info).with(end_payload).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          subject.call(job, 'test_queue') { }
        end
      end

      it 'logs an exception in job' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload)
          expect(logger).to receive(:warn).with(hash_including(exception_payload))
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          expect do
            subject.call(job, 'test_queue') do
              raise ArgumentError, 'some exception'
            end
          end.to raise_error(ArgumentError)
        end
      end

      context 'when the job args are bigger than the maximum allowed' do
        it 'keeps args from the front until they exceed the limit' do
          Timecop.freeze(timestamp) do
            job['args'] = [
              1,
              2,
              'a' * (described_class::MAXIMUM_JOB_ARGUMENTS_LENGTH / 2),
              'b' * (described_class::MAXIMUM_JOB_ARGUMENTS_LENGTH / 2),
              3
            ]

            expected_args = job['args'].take(3) + ['...']

            expect(logger).to receive(:info).with(start_payload.merge('args' => expected_args)).ordered
            expect(logger).to receive(:info).with(end_payload.merge('args' => expected_args)).ordered
            expect(subject).to receive(:log_job_start).and_call_original
            expect(subject).to receive(:log_job_done).and_call_original

            subject.call(job, 'test_queue') { }
          end
        end
      end
    end

    context 'with SIDEKIQ_LOG_ARGUMENTS disabled' do
      it 'logs start and end of job without args' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload.except('args')).ordered
          expect(logger).to receive(:info).with(end_payload.except('args')).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          subject.call(job, 'test_queue') { }
        end
      end

      it 'logs without created_at and enqueued_at fields' do
        Timecop.freeze(timestamp) do
          excluded_fields = %w(created_at enqueued_at args scheduling_latency_s)

          expect(logger).to receive(:info).with(start_payload.except(*excluded_fields)).ordered
          expect(logger).to receive(:info).with(end_payload.except(*excluded_fields)).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          subject.call(job.except("created_at", "enqueued_at"), 'test_queue') { }
        end
      end
    end

    context 'with latency' do
      let(:created_at) { Time.iso8601('2018-01-01T10:00:00.000Z') }
      let(:scheduling_latency_s) { 7200.0 }

      it 'logs with scheduling latency' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload.except('args')).ordered
          expect(logger).to receive(:info).with(end_payload.except('args')).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          subject.call(job, 'test_queue') { }
        end
      end
    end

    context 'with Gitaly and Rugged calls' do
      let(:timing_data) do
        {
          gitaly_calls: 10,
          gitaly_duration: 10000,
          rugged_calls: 1,
          rugged_duration_ms: 5000
        }
      end

      before do
        job.merge!(timing_data)
      end

      it 'logs with Gitaly and Rugged timing data' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload.except('args')).ordered
          expect(logger).to receive(:info).with(end_payload.except('args')).ordered

          subject.call(job, 'test_queue') { }
        end
      end
    end

    context 'when the job performs database queries' do
      before do
        allow(Time).to receive(:now).and_return(timestamp)
        allow(Process).to receive(:clock_gettime).and_call_original
      end

      let(:expected_start_payload) { start_payload.except('args') }

      let(:expected_end_payload) do
        end_payload.except('args').merge('cpu_s' => a_value > 0)
      end

      let(:expected_end_payload_with_db) do
        expected_end_payload.merge(
          'db_duration' => a_value >= 100,
          'db_duration_s' => a_value >= 0.1
        )
      end

      it 'logs the database time' do
        expect(logger).to receive(:info).with(expected_start_payload).ordered
        expect(logger).to receive(:info).with(expected_end_payload_with_db).ordered

        subject.call(job, 'test_queue') { ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);') }
      end

      it 'prevents database time from leaking to the next job' do
        expect(logger).to receive(:info).with(expected_start_payload).ordered
        expect(logger).to receive(:info).with(expected_end_payload_with_db).ordered
        expect(logger).to receive(:info).with(expected_start_payload).ordered
        expect(logger).to receive(:info).with(expected_end_payload).ordered

        subject.call(job, 'test_queue') { ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);') }
        subject.call(job, 'test_queue') { }
      end
    end
  end

  describe '#add_time_keys!' do
    let(:time) { { duration: 0.1231234, cputime: 1.2342345 } }
    let(:payload) { { 'class' => 'my-class', 'message' => 'my-message', 'job_status' => 'my-job-status' } }
    let(:current_utc_time) { Time.now.utc }
    let(:payload_with_time_keys) { { 'class' => 'my-class', 'message' => 'my-message', 'job_status' => 'my-job-status', 'duration' => 0.123123, 'cpu_s' => 1.234235, 'completed_at' => current_utc_time.to_f } }

    subject { described_class.new }

    it 'update payload correctly' do
      Timecop.freeze(current_utc_time) do
        subject.send(:add_time_keys!, time, payload)

        expect(payload).to eq(payload_with_time_keys)
      end
    end
  end
end
