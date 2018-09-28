require 'spec_helper'

describe Gitlab::SidekiqLogging::StructuredLogger do
  describe '#call' do
    let(:timestamp) { Time.new('2018-01-01 12:00:00').utc }
    let(:job) do
      {
        "class" => "TestWorker",
        "args" => [1234, 'hello'],
        "retry" => false,
        "queue" => "cronjob:test_queue",
        "queue_namespace" => "cronjob",
        "jid" => "da883554ee4fe414012f5f42",
        "created_at" => timestamp.to_f,
        "enqueued_at" => timestamp.to_f
      }
    end
    let(:logger) { double() }
    let(:start_payload) do
      job.merge(
        'message' => 'TestWorker JID-da883554ee4fe414012f5f42: start',
        'job_status' => 'start',
        'pid' => Process.pid,
        'created_at' => timestamp.iso8601(3),
        'enqueued_at' => timestamp.iso8601(3)
      )
    end
    let(:end_payload) do
      start_payload.merge(
        'message' => 'TestWorker JID-da883554ee4fe414012f5f42: done: 0.0 sec',
        'job_status' => 'done',
        'duration' => 0.0,
        "completed_at" => timestamp.iso8601(3)
      )
    end
    let(:exception_payload) do
      end_payload.merge(
        'message' => 'TestWorker JID-da883554ee4fe414012f5f42: fail: 0.0 sec',
        'job_status' => 'fail',
        'error' => ArgumentError,
        'error_message' => 'some exception'
      )
    end

    before do
      allow(Sidekiq).to receive(:logger).and_return(logger)

      allow(subject).to receive(:current_time).and_return(timestamp.to_f)
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
          # This excludes the exception_backtrace
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
    end

    context 'with SIDEKIQ_LOG_ARGUMENTS disabled' do
      it 'logs start and end of job' do
        Timecop.freeze(timestamp) do
          start_payload.delete('args')

          expect(logger).to receive(:info).with(start_payload).ordered
          expect(logger).to receive(:info).with(end_payload).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          subject.call(job, 'test_queue') { }
        end
      end
    end
  end
end
