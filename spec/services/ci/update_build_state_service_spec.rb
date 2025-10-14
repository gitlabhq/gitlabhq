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

  public

  describe 'runner acknowledgment workflow' do
    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner, system_xid: 'abc') }

    let(:redis_klass) { Gitlab::Redis::SharedState }

    context 'when build is waiting for runner acknowledgment', :clean_gitlab_redis_cache do
      let(:build) do
        create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner,
          ack_runner_manager: runner_manager)
      end

      context 'when state is pending' do
        let(:params) { { state: 'pending' } }

        context 'when build is not assigned to a runner manager' do
          specify 'should not have runner manager assigned' do
            expect(build.runner_manager).to be_nil
          end

          it 'returns 200 OK status for keep-alive signal' do
            result = execute

            expect(result.status).to eq 200
            expect(result.backoff).to be_nil
          end

          it 'does not assign runner manager' do
            expect { execute }.to not_change { build.reload.runner_manager }.from(nil)
          end

          it 'updates runner manager heartbeat' do
            expect(build).to receive(:heartbeat_runner_ack_wait).with(runner_manager.id)

            execute
          end

          it 'resets ttl', :freeze_time do
            service.execute

            consume_redis_ttl(runner_build_ack_queue_key)

            # Redis key TTL should increase by at least 1 second
            expect { execute }.to change { redis_ttl(runner_build_ack_queue_key) }.by_at_least(1)
          end

          it 'does not change build state' do
            expect { execute }.not_to change { build.reload.status }
          end
        end

        context 'when build is already assigned to a runner manager (race condition)' do
          before do
            allow(build).to receive(:runner_manager).and_return(runner_manager)
          end

          it 'returns 409 Conflict status' do
            result = execute

            expect(result.status).to eq 409
            expect(result.backoff).to be_nil
          end

          it 'does not change build state' do
            expect { execute }.not_to change { build.reload.status }
          end

          it 'does not reset ttl', :freeze_time do
            service.execute

            consume_redis_ttl(runner_build_ack_queue_key)

            expect { execute }.not_to change { redis_ttl(runner_build_ack_queue_key) }
          end
        end
      end

      context 'when state is running' do
        let(:params) { { state: 'running' } }

        context 'when runner manager exists' do
          it 'transitions job to running state and returns 200 OK' do
            expect(build).to receive(:run!)

            result = execute

            expect(result.status).to eq 200
            expect(result.backoff).to be_nil
          end

          it 'assigns the runner manager to the build' do
            allow(build).to receive(:run!)

            expect { execute }.to change { build.reload.runner_manager }.from(nil).to(runner_manager)
          end
        end

        context 'when runner manager does not exist' do
          let(:build) do
            create(:ci_build, :pending, pipeline: pipeline, runner: runner).tap do |b|
              b.set_waiting_for_runner_ack(non_existing_record_id)
            end
          end

          it 'returns 400 Bad Request status' do
            expect(execute.status).to eq 400
            expect(execute.backoff).to be_nil
          end

          it 'does not change build state or runner manager' do
            expect { execute }.to not_change { build.reload.status }
              .and not_change { build.reload.runner_manager }
          end

          it 'does not change ttl' do
            expect { execute }.not_to change { redis_ttl(runner_build_ack_queue_key) }
          end

          it 'does not transition build to running' do
            expect(build).not_to receive(:run!)

            execute
          end
        end
      end

      context 'when state is invalid for two-phase commit workflow' do
        %w[success failed].each do |state|
          context "when state is #{state}" do
            let(:params) { { state: state } }

            it 'returns 400 Bad Request status' do
              result = execute

              expect(result.status).to eq 400
              expect(result.backoff).to be_nil
            end

            it 'does not change build state' do
              expect { execute }.not_to change { build.reload.status }
            end

            it 'does not change ttl' do
              expect { execute }.not_to change { redis_ttl(runner_build_ack_queue_key) }
            end
          end
        end
      end

      context 'when handling edge cases in runner ack workflow' do
        context 'when build state is empty' do
          let(:params) { { state: '' } }

          it 'returns 400 Bad Request status' do
            result = execute

            expect(result.status).to eq 400
            expect(result.backoff).to be_nil
          end
        end

        context 'when build state is nil' do
          let(:params) { {} }

          it 'returns 400 Bad Request status' do
            result = execute

            expect(result.status).to eq 400
            expect(result.backoff).to be_nil
          end
        end
      end
    end

    context 'when build is not waiting for runner acknowledgment' do
      let(:build) { create(:ci_build, :running, runner: runner, runner_manager: runner_manager, pipeline: pipeline) }
      let(:params) { { state: 'success' } }

      it 'skips runner ack workflow and proceeds with normal processing' do
        expect(build).not_to receive(:heartbeat_runner_ack_wait)
        expect(build).not_to receive(:run!)
        expect(build).to receive(:success!)
        expect(service).to receive(:accept_available?).and_call_original

        expect(execute.status).to eq 200
      end
    end

    context 'when allow_runner_job_acknowledgement feature flag is disabled' do
      before do
        stub_feature_flags(allow_runner_job_acknowledgement: false)
      end

      context 'when build would normally be waiting for runner acknowledgment', :clean_gitlab_redis_cache do
        let(:build) do
          create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner,
            ack_runner_manager: runner_manager)
        end

        context 'when state is pending' do
          let(:params) { { state: 'pending' } }

          it 'returns 200 OK despite feature flag' do
            result = execute

            expect(result.status).to eq 200
            expect(result.backoff).to be_nil
          end

          it 'does not change build state' do
            expect { execute }.not_to change { build.reload.status }
          end

          it 'updates runner manager heartbeat' do
            expect(build).to receive(:heartbeat_runner_ack_wait).with(runner_manager.id)

            execute
          end
        end

        context 'when state is running' do
          let(:params) { { state: 'running' } }

          it 'returns 200 OK despite feature flag' do
            result = execute

            expect(result.status).to eq 200
            expect(result.backoff).to be_nil
          end

          it 'changes build state to running' do
            expect { execute }.to change { build.reload.status }.from('pending').to('running')
          end
        end
      end

      context 'when build is not waiting for runner acknowledgment' do
        let(:build) { create(:ci_build, :running, runner: runner, runner_manager: runner_manager, pipeline: pipeline) }
        let(:params) { { state: 'success' } }

        it 'proceeds with normal processing' do
          expect(build).not_to receive(:heartbeat_runner_ack_wait)
          expect(build).to receive(:success!)
          expect(service).to receive(:accept_available?).and_call_original

          expect(execute.status).to eq 200
        end
      end
    end

    private

    def runner_build_ack_queue_key
      build.send(:runner_ack_queue).redis_key
    end

    def redis_ttl(cache_key)
      redis_klass.with do |redis|
        redis.ttl(cache_key)
      end
    end

    def consume_redis_ttl(cache_key)
      redis_klass.with do |redis|
        redis.set(cache_key, runner_manager.id, ex: Gitlab::Ci::Build::RunnerAckQueue::RUNNER_ACK_QUEUE_EXPIRY_TIME - 1,
          nx: false)
      end
    end
  end
end
