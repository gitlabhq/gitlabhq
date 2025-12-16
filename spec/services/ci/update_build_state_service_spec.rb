# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateBuildStateService, '#execute', feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :running, pipeline: pipeline) }
  let(:metrics) { spy('metrics') }
  let(:service) { described_class.new(build, params) }

  subject(:execute) { service.execute }

  before do
    stub_application_setting(ci_job_live_trace_enabled: true)
  end

  context 'when build has unknown failure reason' do
    let(:params) do
      {
        output: { checksum: 'crc32:12345678', bytesize: 123 },
        state: 'failed',
        failure_reason: 'no idea here',
        exit_code: 42
      }
    end

    it 'updates a build status' do
      result = execute

      expect(build).to be_failed
      expect(result.status).to eq 200
    end
  end

  context 'when build has failed' do
    let(:params) do
      {
        output: { checksum: 'crc32:12345678', bytesize: 123 },
        state: 'failed',
        failure_reason: 'script_failure',
        exit_code: 7
      }
    end

    it 'sends a build failed event to Snowplow' do
      expect(::Ci::TrackFailedBuildWorker)
        .to receive(:perform_async).with(build.id, params[:exit_code], params[:failure_reason])

      execute
    end
  end

  context 'when build does not have checksum' do
    context 'when state has changed' do
      let(:params) { { state: 'success' } }

      it 'updates a state of a running build' do
        execute

        expect(build).to be_success
      end

      it 'returns 200 OK status' do
        expect(execute.status).to eq 200
      end

      it 'does not increment finalized trace metric' do
        execute_with_stubbed_metrics!

        expect(metrics)
          .not_to have_received(:increment_trace_operation)
          .with(operation: :finalized)
      end
    end

    context 'when it is a heartbeat request' do
      let(:params) { { state: 'success' } }

      it 'updates a build timestamp' do
        expect { execute }.to change { build.updated_at }
      end
    end

    context 'when state is unknown' do
      let(:params) { { state: 'unknown' } }

      it 'responds with 400 bad request' do
        expect(execute.status).to eq 400
        expect(build).to be_running
      end
    end
  end

  context 'when build has a checksum' do
    let(:params) do
      {
        output: { checksum: 'crc32:12345678', bytesize: 123 },
        state: 'failed',
        failure_reason: 'script_failure',
        exit_code: 42
      }
    end

    context 'when build does not have associated trace chunks' do
      it 'updates a build status' do
        result = execute

        expect(build).to be_failed
        expect(result.status).to eq 200
      end

      it 'updates the allow_failure flag' do
        expect(build)
          .to receive(:drop_with_exit_code!)
          .with('script_failure', 42)
          .and_call_original

        execute
      end

      it 'does not increment invalid trace metric' do
        execute_with_stubbed_metrics!

        expect(metrics)
          .not_to have_received(:increment_trace_operation)
          .with(operation: :invalid)
      end

      it 'does not increment chunks_invalid_checksum trace metric' do
        execute_with_stubbed_metrics!

        expect(metrics)
          .not_to have_received(:increment_error_counter)
          .with(error_reason: :chunks_invalid_checksum)
      end
    end

    context 'when build trace has been migrated' do
      before do
        create(:ci_build_trace_chunk, :persisted, build: build, initial_data: 'abcd')
      end

      it 'updates a build state' do
        execute

        expect(build).to be_failed
      end

      it 'updates the allow_failure flag' do
        expect(build)
          .to receive(:drop_with_exit_code!)
          .with('script_failure', 42)
          .and_call_original

        execute
      end

      it 'responds with 200 OK status' do
        expect(execute.status).to eq 200
      end

      it 'does not set a backoff value' do
        expect(execute.backoff).to be_nil
      end

      it 'increments trace finalized operation metric' do
        execute_with_stubbed_metrics!

        expect(metrics)
          .to have_received(:increment_trace_operation)
          .with(operation: :finalized)
      end

      it 'records migration duration in a histogram' do
        freeze_time do
          create(:ci_build_pending_state, build: build, created_at: 0.5.seconds.ago)

          execute_with_stubbed_metrics!
        end

        expect(metrics)
          .to have_received(:observe_migration_duration)
          .with(0.5)
      end

      context 'when trace checksum is not valid' do
        it 'increments invalid trace metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :invalid)
        end

        it 'increments chunks_invalid_checksum trace metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_checksum)
        end
      end

      context 'when trace checksum is valid' do
        let(:params) do
          { output: { checksum: 'crc32:ed82cd11', bytesize: 4 }, state: 'success' }
        end

        it 'does not increment invalid or corrupted trace metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .not_to have_received(:increment_trace_operation)
            .with(operation: :invalid)

          expect(metrics)
            .not_to have_received(:increment_trace_operation)
            .with(operation: :corrupted)

          expect(metrics)
            .not_to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_checksum)

          expect(metrics)
            .not_to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_size)
        end

        context 'when using deprecated parameters' do
          let(:params) do
            { checksum: 'crc32:ed82cd11', state: 'success' }
          end

          it 'does not increment invalid or corrupted trace metric' do
            execute_with_stubbed_metrics!

            expect(metrics)
              .not_to have_received(:increment_trace_operation)
              .with(operation: :invalid)

            expect(metrics)
              .not_to have_received(:increment_trace_operation)
              .with(operation: :corrupted)

            expect(metrics)
              .not_to have_received(:increment_error_counter)
              .with(error_reason: :chunks_invalid_checksum)

            expect(metrics)
              .not_to have_received(:increment_error_counter)
              .with(error_reason: :chunks_invalid_size)
          end
        end
      end

      context 'when trace checksum is invalid and the log is corrupted' do
        let(:params) do
          { output: { checksum: 'crc32:12345678', bytesize: 1 }, state: 'success' }
        end

        it 'increments invalid and corrupted trace metrics' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :invalid)

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :corrupted)

          expect(metrics)
            .to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_checksum)

          expect(metrics)
            .to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_size)
        end
      end

      context 'when trace checksum is invalid but the log seems fine' do
        let(:params) do
          { output: { checksum: 'crc32:12345678', bytesize: 4 }, state: 'success' }
        end

        it 'does not increment corrupted trace metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :invalid)

          expect(metrics)
            .to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_checksum)

          expect(metrics)
            .not_to have_received(:increment_trace_operation)
            .with(operation: :corrupted)

          expect(metrics)
            .not_to have_received(:increment_error_counter)
            .with(error_reason: :chunks_invalid_size)
        end
      end

      context 'when failed to acquire a build trace lock' do
        it 'accepts a state update request' do
          build.trace.lock do
            expect(execute.status).to eq 202
          end
        end

        it 'increment locked trace metric' do
          build.trace.lock do
            execute_with_stubbed_metrics!

            expect(metrics)
              .to have_received(:increment_trace_operation)
              .with(operation: :locked)
          end
        end
      end
    end

    context 'when build trace has not been migrated yet' do
      before do
        create(:ci_build_trace_chunk, :redis_with_data, build: build)
      end

      it 'does not update a build state' do
        execute

        expect(build).to be_running
      end

      it 'responds with 202 accepted' do
        expect(execute.status).to eq 202
      end

      it 'sets a request backoff value' do
        expect(execute.backoff.to_i).to be > 0
      end

      it 'schedules live chunks for migration' do
        expect(Ci::BuildTraceChunkFlushWorker)
          .to receive(:perform_async)
          .with(build.trace_chunks.first.id)

        execute
      end

      it 'creates a pending state record' do
        execute

        build.pending_state.then do |status|
          expect(status).to be_present
          expect(status.state).to eq 'failed'
          expect(status.trace_checksum).to eq 'crc32:12345678'
          expect(status.failure_reason).to eq 'script_failure'
        end
      end

      it 'increments trace accepted operation metric' do
        execute_with_stubbed_metrics!

        expect(metrics)
          .to have_received(:increment_trace_operation)
          .with(operation: :accepted)
      end

      it 'does not increment invalid trace metric' do
        execute_with_stubbed_metrics!

        expect(metrics)
          .not_to have_received(:increment_trace_operation)
          .with(operation: :invalid)

        expect(metrics)
          .not_to have_received(:increment_error_counter)
          .with(error_reason: :chunks_invalid_checksum)
      end

      context 'when build pending state is outdated' do
        before do
          build.create_pending_state(
            state: 'failed',
            trace_checksum: 'crc32:12345678',
            failure_reason: 'script_failure',
            created_at: 10.minutes.ago
          )
        end

        it 'responds with 200 OK' do
          expect(execute.status).to eq 200
        end

        it 'updates build state' do
          execute

          expect(build.reload).to be_failed
          expect(build.failure_reason).to eq 'script_failure'
        end

        it 'increments discarded traces metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :discarded)
        end

        it 'does not increment finalized trace metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .not_to have_received(:increment_trace_operation)
            .with(operation: :finalized)
        end
      end

      context 'when build pending state has changes' do
        before do
          build.create_pending_state(
            state: 'success',
            created_at: 10.minutes.ago
          )
        end

        it 'uses stored state and responds with 200 OK' do
          expect(execute.status).to eq 200
        end

        it 'increments conflict trace metric' do
          execute_with_stubbed_metrics!

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :conflict)
        end
      end

      context 'when live traces are disabled' do
        before do
          stub_application_setting(ci_job_live_trace_enabled: false)
        end

        it 'responds with 200 OK' do
          expect(execute.status).to eq 200
        end
      end
    end
  end

  private

  def execute_with_stubbed_metrics!
    described_class
      .new(build, params, metrics)
      .execute
  end
end
