# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqLogging::StructuredLogger do
  before do
    # We disable a memory instrumentation feature
    # as this requires a special patched Ruby
    allow(Gitlab::Memory::Instrumentation).to receive(:available?) { false }
  end

  describe '#call', :request_store do
    include_context 'structured_logger'

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

          call_subject(job, 'test_queue') { }
        end
      end

      it 'logs real job wrapped by active job worker' do
        wrapped_job = job.merge(
          "class" => "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
          "wrapped" => "TestWorker"
        )

        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload).ordered
          expect(logger).to receive(:info).with(end_payload).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          call_subject(wrapped_job, 'test_queue') { }
        end
      end

      it 'logs an exception in job' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload)
          expect(logger).to receive(:warn).with(include(exception_payload))
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          expect do
            call_subject(job, 'test_queue') do
              raise ArgumentError, 'Something went wrong'
            end
          end.to raise_error(ArgumentError)
        end
      end

      it 'logs the root cause of an Sidekiq::JobRetry::Skip exception in the job' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload)
          expect(logger).to receive(:warn).with(include(exception_payload))
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          expect do
            call_subject(job, 'test_queue') do
              raise ArgumentError, 'Something went wrong'
            rescue StandardError
              raise Sidekiq::JobRetry::Skip
            end
          end.to raise_error(Sidekiq::JobRetry::Skip)
        end
      end

      it 'logs the root cause of an Sidekiq::JobRetry::Handled exception in the job' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload)
          expect(logger).to receive(:warn).with(include(exception_payload))
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          expect do
            call_subject(job, 'test_queue') do
              raise ArgumentError, 'Something went wrong'
            rescue StandardError
              raise Sidekiq::JobRetry::Handled
            end
          end.to raise_error(Sidekiq::JobRetry::Handled)
        end
      end

      it 'keeps Sidekiq::JobRetry::Handled exception if the cause does not exist' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload)
          expect(logger).to receive(:warn).with(
            include(
              'message' => 'TestWorker JID-da883554ee4fe414012f5f42: fail: 0.0 sec',
              'job_status' => 'fail',
              'error_class' => 'Sidekiq::JobRetry::Skip',
              'error_message' => 'Sidekiq::JobRetry::Skip'
            )
          )
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          expect do
            call_subject(job, 'test_queue') do
              raise Sidekiq::JobRetry::Skip
            end
          end.to raise_error(Sidekiq::JobRetry::Skip)
        end
      end

      it 'does not modify the job' do
        Timecop.freeze(timestamp) do
          job_copy = job.deep_dup

          allow(logger).to receive(:info)
          allow(subject).to receive(:log_job_start).and_call_original
          allow(subject).to receive(:log_job_done).and_call_original

          call_subject(job, 'test_queue') do
            expect(job).to eq(job_copy)
          end
        end
      end

      it 'does not modify the wrapped job' do
        Timecop.freeze(timestamp) do
          wrapped_job = job.merge(
            "class" => "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
            "wrapped" => "TestWorker"
          )
          job_copy = wrapped_job.deep_dup

          allow(logger).to receive(:info)
          allow(subject).to receive(:log_job_start).and_call_original
          allow(subject).to receive(:log_job_done).and_call_original

          call_subject(wrapped_job, 'test_queue') do
            expect(wrapped_job).to eq(job_copy)
          end
        end
      end
    end

    context 'with SIDEKIQ_LOG_ARGUMENTS disabled' do
      before do
        stub_env('SIDEKIQ_LOG_ARGUMENTS', '0')
      end

      it 'logs start and end of job without args' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload.except('args')).ordered
          expect(logger).to receive(:info).with(end_payload.except('args')).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          call_subject(job, 'test_queue') { }
        end
      end

      it 'logs without created_at and enqueued_at fields' do
        Timecop.freeze(timestamp) do
          excluded_fields = %w(created_at enqueued_at args scheduling_latency_s)

          expect(logger).to receive(:info).with(start_payload.except(*excluded_fields)).ordered
          expect(logger).to receive(:info).with(end_payload.except(*excluded_fields)).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          call_subject(job.except("created_at", "enqueued_at"), 'test_queue') { }
        end
      end
    end

    context 'with latency' do
      let(:created_at) { Time.iso8601('2018-01-01T10:00:00.000Z') }
      let(:scheduling_latency_s) { 7200.0 }

      it 'logs with scheduling latency' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload).ordered
          expect(logger).to receive(:info).with(end_payload).ordered
          expect(subject).to receive(:log_job_start).and_call_original
          expect(subject).to receive(:log_job_done).and_call_original

          call_subject(job, 'test_queue') { }
        end
      end
    end

    context 'with Gitaly, Rugged, and Redis calls' do
      let(:timing_data) do
        {
          gitaly_calls: 10,
          gitaly_duration_s: 10000,
          rugged_calls: 1,
          rugged_duration_s: 5000,
          redis_calls: 3,
          redis_duration_s: 1234
        }
      end

      let(:expected_end_payload) do
        end_payload.merge(timing_data.stringify_keys)
      end

      before do
        allow(::Gitlab::InstrumentationHelper).to receive(:add_instrumentation_data).and_wrap_original do |method, values|
          method.call(values)
          values.merge!(timing_data)
        end
      end

      it 'logs with Gitaly and Rugged timing data', :aggregate_failures do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(start_payload).ordered
          expect(logger).to receive(:info).with(expected_end_payload).ordered

          call_subject(job, 'test_queue') { }
        end
      end
    end

    context 'when the job performs database queries' do
      include_context 'clear DB Load Balancing configuration'

      before do
        allow(Time).to receive(:now).and_return(timestamp)
        allow(Process).to receive(:clock_gettime).and_call_original
      end

      let(:expected_start_payload) { start_payload }

      let(:expected_end_payload) do
        end_payload.merge('cpu_s' => a_value >= 0)
      end

      let(:expected_end_payload_with_db) do
        expected_end_payload.merge(
          'db_duration_s' => a_value >= 0.1,
          'db_count' => a_value >= 1,
          'db_cached_count' => 0,
          'db_write_count' => 0
        )
      end

      shared_examples 'performs database queries' do
        it 'logs the database time', :aggregate_errors do
          expect(logger).to receive(:info).with(expected_start_payload).ordered
          expect(logger).to receive(:info).with(expected_end_payload_with_db).ordered

          call_subject(job, 'test_queue') do
            ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);')
          end
        end

        it 'prevents database time from leaking to the next job', :aggregate_errors do
          expect(logger).to receive(:info).with(expected_start_payload).ordered
          expect(logger).to receive(:info).with(expected_end_payload_with_db).ordered
          expect(logger).to receive(:info).with(expected_start_payload).ordered
          expect(logger).to receive(:info).with(expected_end_payload).ordered

          call_subject(job.dup, 'test_queue') do
            ActiveRecord::Base.connection.execute('SELECT pg_sleep(0.1);')
          end

          Gitlab::SafeRequestStore.clear!

          call_subject(job.dup, 'test_queue') { }
        end
      end

      context 'when load balancing is disabled' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(false)
        end

        let(:expected_end_payload_with_db) do
          expected_end_payload.merge(
            'db_duration_s' => a_value >= 0.1,
            'db_count' => a_value >= 1,
            'db_cached_count' => 0,
            'db_write_count' => 0
          )
        end

        include_examples 'performs database queries'
      end

      context 'when load balancing is enabled' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
        end

        let(:dbname) { ::Gitlab::Database.dbname(ActiveRecord::Base.connection) }

        let(:expected_end_payload_with_db) do
          expected_end_payload.merge(
            'db_duration_s' => a_value >= 0.1,
            'db_count' => a_value >= 1,
            'db_cached_count' => 0,
            'db_write_count' => 0,
            'db_replica_count' => 0,
            'db_replica_cached_count' => 0,
            'db_replica_wal_count' => 0,
            'db_replica_duration_s' => a_value >= 0,
            'db_primary_count' => a_value >= 1,
            'db_primary_cached_count' => 0,
            'db_primary_wal_count' => 0,
            'db_primary_duration_s' => a_value > 0,
            "db_primary_#{dbname}_duration_s" => a_value > 0,
            'db_primary_wal_cached_count' => 0,
            'db_replica_wal_cached_count' => 0
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
            'db_write_count' => 0,
            'db_replica_count' => 0,
            'db_replica_cached_count' => 0,
            'db_replica_wal_count' => 0,
            'db_replica_duration_s' => 0,
            'db_primary_count' => 0,
            'db_primary_cached_count' => 0,
            'db_primary_wal_count' => 0,
            'db_primary_wal_cached_count' => 0,
            'db_replica_wal_cached_count' => 0,
            'db_primary_duration_s' => 0
          )
        end

        include_examples 'performs database queries'
      end
    end

    context 'when the job uses load balancing capabilities' do
      let(:expected_payload) { { 'load_balancing_strategy' => 'retry' } }

      before do
        allow(Time).to receive(:now).and_return(timestamp)
        allow(Process).to receive(:clock_gettime).and_call_original
      end

      it 'logs the database chosen' do
        expect(logger).to receive(:info).with(start_payload).ordered
        expect(logger).to receive(:info).with(include(expected_payload)).ordered

        call_subject(job, 'test_queue') do
          job['load_balancing_strategy'] = 'retry'
        end
      end
    end

    context 'when there is extra metadata set for the done log' do
      let(:expected_start_payload) { start_payload }

      let(:expected_end_payload) do
        end_payload.merge("#{ApplicationWorker::LOGGING_EXTRA_KEY}.key1" => 15, "#{ApplicationWorker::LOGGING_EXTRA_KEY}.key2" => 16)
      end

      it 'logs it in the done log' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(expected_start_payload).ordered
          expect(logger).to receive(:info).with(expected_end_payload).ordered

          call_subject(job, 'test_queue') do
            job["#{ApplicationWorker::LOGGING_EXTRA_KEY}.key1"] = 15
            job["#{ApplicationWorker::LOGGING_EXTRA_KEY}.key2"] = 16
            job['key that will be ignored because it does not start with extra.'] = 17
          end
        end
      end
    end

    context 'when instrumentation data is not loaded' do
      before do
        allow(logger).to receive(:info)
      end

      it 'does not raise exception' do
        expect { subject.call(job.dup, 'test_queue') {} }.not_to raise_error
      end
    end

    context 'when the job payload is compressed' do
      let(:compressed_args) { "eJyLVspIzcnJV4oFAA88AxE=" }
      let(:expected_start_payload) do
        start_payload.merge(
          'args' => ['[COMPRESSED]'],
          'job_size_bytes' => Sidekiq.dump_json([compressed_args]).bytesize,
          'compressed' => true
        )
      end

      let(:expected_end_payload) do
        end_payload.merge(
          'args' => ['[COMPRESSED]'],
          'job_size_bytes' => Sidekiq.dump_json([compressed_args]).bytesize,
          'compressed' => true
        )
      end

      it 'logs it in the done log' do
        Timecop.freeze(timestamp) do
          expect(logger).to receive(:info).with(expected_start_payload).ordered
          expect(logger).to receive(:info).with(expected_end_payload).ordered

          job['args'] = [compressed_args]
          job['compressed'] = true

          call_subject(job, 'test_queue') do
            ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor.decompress(job)
          end
        end
      end
    end
  end

  describe '#add_time_keys!' do
    let(:time) { { duration: 0.1231234 } }
    let(:payload) { { 'class' => 'my-class', 'message' => 'my-message', 'job_status' => 'my-job-status' } }
    let(:current_utc_time) { Time.now.utc }

    let(:payload_with_time_keys) do
      { 'class' => 'my-class',
        'message' => 'my-message',
        'job_status' => 'my-job-status',
        'duration_s' => 0.123123,
        'completed_at' => current_utc_time.to_f }
    end

    subject { described_class.new }

    it 'update payload correctly' do
      Timecop.freeze(current_utc_time) do
        subject.send(:add_time_keys!, time, payload)

        expect(payload).to eq(payload_with_time_keys)
      end
    end
  end
end
