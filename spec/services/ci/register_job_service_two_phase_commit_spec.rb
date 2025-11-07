# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RegisterJobService, 'two-phase commit feature', feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project, :repository) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }
  let_it_be(:runner, freeze: true) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:runner_manager, freeze: true) { create(:ci_runner_machine, runner: runner) }

  let(:service) { described_class.new(runner, runner_manager) }

  describe '#execute', :aggregate_failures do
    let!(:build) { create(:ci_build, :pending, :queued, pipeline: pipeline) }

    subject(:execute) { service.execute(runner_params) }

    shared_examples 'the legacy workflow (direct transition to running)' do
      it 'transitions job directly to running state (legacy behavior)' do
        expect(build).to be_pending
        expect(build.runner_id).to be_nil

        result = execute

        expect(result).to be_valid
        expect(result.build).to eq(build)

        build.reload
        expect(build).to be_running
        expect(build.runner_id).to eq(runner.id)
        expect(build.runner_manager).to eq(runner_manager)
      end

      it 'removes job from pending builds queue' do
        expect { execute }.to change { Ci::PendingBuild.where(build: build).count }.from(1).to(0)
      end

      it 'creates running build tracking entry' do
        expect { execute }.to change { Ci::RunningBuild.count }.by(1)
      end

      it 'does not set waiting for runner ack' do
        expect(execute).to be_valid
        expect(build.reload.runner_ack_wait_status).to eq :not_waiting
      end

      context 'when logger is enabled' do
        before do
          stub_const('Ci::RegisterJobService::Logger::MAX_DURATION', 0)
        end

        it 'logs the instrumentation' do
          expect(Gitlab::AppJsonLogger).to receive(:info).once.with(
            hash_including(
              class: 'Ci::RegisterJobService::Logger',
              message: 'RegisterJobService exceeded maximum duration',
              runner_id: runner.id,
              runner_type: runner.runner_type,
              assign_runner_run_duration_s: { count: 1, max: anything, sum: anything }
            )
          )

          execute
        end
      end
    end

    context 'when runner supports two_phase_job_commit feature' do
      let(:runner_params) do
        {
          info: {
            features: {
              two_phase_job_commit: true
            }
          }
        }
      end

      it 'assigns runner but keeps job in pending state' do
        expect(build).to be_pending
        expect(build.runner_id).to be_nil

        expect(::Ci::RetryStuckWaitingJobWorker).to receive(:perform_in)
          .with(Gitlab::Ci::Build::RunnerAckQueue::RUNNER_ACK_QUEUE_EXPIRY_TIME, build.id)

        result = execute

        expect(result).to be_valid
        expect(result.build).to eq(build)

        build.reload
        expect(build).to be_pending
        expect(build.runner_id).to eq(runner.id)
        expect(build.runner_manager).to be_nil
      end

      it 'removes job from pending builds queue' do
        expect { execute }.to change { Ci::PendingBuild.where(build: build).count }.from(1).to(0)
      end

      it 'does not create running build tracking entry' do
        expect { execute }.not_to change { Ci::RunningBuild.count }
      end

      context 'when logger is enabled' do
        before do
          stub_const('Ci::RegisterJobService::Logger::MAX_DURATION', 0)
        end

        it 'logs the instrumentation' do
          expect(Gitlab::AppJsonLogger).to receive(:info).once.with(
            hash_including(
              class: 'Ci::RegisterJobService::Logger',
              message: 'RegisterJobService exceeded maximum duration',
              runner_id: runner.id,
              runner_type: runner.runner_type,
              total_duration_s: anything,
              process_queue_duration_s: anything,
              retrieve_queue_duration_s: anything,
              process_build_duration_s: { count: 1, max: anything, sum: anything },
              process_build_runner_matched_duration_s: { count: 1, max: anything, sum: anything },
              process_build_present_build_duration_s: { count: 1, max: anything, sum: anything },
              present_build_logs_duration_s: { count: 1, max: anything, sum: anything },
              present_build_response_json_duration_s: { count: 1, max: anything, sum: anything },
              process_build_assign_runner_duration_s: { count: 1, max: anything, sum: anything },
              assign_runner_waiting_duration_s: { count: 1, max: anything, sum: anything }
            )
          )

          execute
        end
      end

      context 'when allow_runner_job_acknowledgement feature flag is disabled' do
        before do
          stub_feature_flags(allow_runner_job_acknowledgement: false)
        end

        it_behaves_like 'the legacy workflow (direct transition to running)' # despite two_phase_job_commit support
      end

      context 'when operations fail during two-phase commit assignment' do
        let(:redis_klass) { Gitlab::Redis::SharedState }

        context 'when Redis fails' do
          before do
            redis_klass.with do |redis|
              allow(redis).to receive(:set).and_call_original
              allow(redis).to receive(:set)
                .with(runner_build_ack_queue_key, runner_manager.id, anything)
                .and_raise(Redis::CannotConnectError)
            end
          end

          it 'rolls back runner assignment and Redis state' do
            expect(Ci::RetryStuckWaitingJobWorker).not_to receive(:perform_in)
            allow_next_instance_of(Gitlab::Ci::Queue::Metrics) do |metrics|
              allow(metrics).to receive(:increment_queue_operation)
              expect(metrics).not_to receive(:increment_queue_operation).with(:runner_assigned_waiting)
            end

            expect { execute }
              .to not_change { build.reload.queuing_entry }.from(an_instance_of(Ci::PendingBuild))
              .and not_change { build.reload.runner_id }.from(nil)
              .and not_change { build.reload.status }.from('pending')
          end
        end

        context 'when build save fails' do
          before do
            allow_next_found_instance_of(Ci::Build) do |build|
              allow(build).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
            end
          end

          it 'rolls back runner assignment and Redis state' do
            expect(Ci::RetryStuckWaitingJobWorker).not_to receive(:perform_in)
            allow_next_instance_of(Gitlab::Ci::Queue::Metrics) do |metrics|
              allow(metrics).to receive(:increment_queue_operation)
              expect(metrics).not_to receive(:increment_queue_operation).with(:runner_assigned_waiting)
            end

            expect { execute }
              .to not_change { build.reload.queuing_entry }.from(an_instance_of(Ci::PendingBuild))
              .and not_change { build.reload.runner_id }.from(nil)
              .and not_change { build.reload.status }.from('pending')
              .and not_change { build.reload.runner_ack_wait_status }.from(:not_waiting)
              .and not_change { redis_ack_pending_key_count }.from(0)
          end
        end

        context 'when queue removal fails' do
          it 'rolls back runner assignment and Redis state' do
            expect(Ci::RetryStuckWaitingJobWorker).not_to receive(:perform_in)
            allow_next_instance_of(Gitlab::Ci::Queue::Metrics) do |metrics|
              allow(metrics).to receive(:increment_queue_operation)
              expect(metrics).not_to receive(:increment_queue_operation).with(:runner_assigned_waiting)
            end
            allow_next_instance_of(Ci::UpdateBuildQueueService) do |service|
              expect(service).to receive(:remove!).with(build).and_raise(ActiveRecord::StatementInvalid)
            end

            expect { execute }
              .to not_change { build.reload.queuing_entry }.from(an_instance_of(Ci::PendingBuild))
              .and not_change { build.reload.runner_id }.from(nil)
              .and not_change { build.reload.status }.from('pending')
              .and not_change { build.reload.runner_ack_wait_status }.from(:not_waiting)
              .and not_change { redis_ack_pending_key_count }.from(0)
          end
        end
      end

      private

      def runner_build_ack_queue_key
        build.send(:runner_ack_queue).redis_key
      end

      def redis_ack_pending_key_count
        redis_klass.with do |redis|
          redis.exists(runner_build_ack_queue_key)
        end
      end
    end

    context 'when runner does not support two_phase_job_commit feature' do
      let(:runner_params) do
        {
          info: {
            features: {
              other_feature: true
            }
          }
        }
      end

      it_behaves_like 'the legacy workflow (direct transition to running)'
    end

    context 'when runner has no features specified' do
      let(:runner_params) { { info: {} } }

      it_behaves_like 'the legacy workflow (direct transition to running)'
    end

    context 'when two_phase_job_commit feature is explicitly disabled' do
      let(:runner_params) do
        {
          info: {
            features: {
              two_phase_job_commit: false
            }
          }
        }
      end

      it_behaves_like 'the legacy workflow (direct transition to running)'

      context 'when allow_runner_job_acknowledgement feature flag is disabled' do
        before do
          stub_feature_flags(allow_runner_job_acknowledgement: false)
        end

        it_behaves_like 'the legacy workflow (direct transition to running)'
      end
    end
  end

  describe '#runner_supports_job_acknowledgment?' do
    let(:build) { create(:ci_build, :pending, :queued, pipeline: pipeline) }

    subject { service.send(:runner_supports_job_acknowledgment?, build, params) }

    context 'when two_phase_job_commit feature is true' do
      let(:params) { { info: { features: { two_phase_job_commit: true } } } }

      it { is_expected.to be true }

      context 'when allow_runner_job_acknowledgement feature flag is disabled' do
        before do
          stub_feature_flags(allow_runner_job_acknowledgement: false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when two_phase_job_commit feature is false' do
      let(:params) { { info: { features: { two_phase_job_commit: false } } } }

      it { is_expected.to be false }
    end

    context 'when two_phase_job_commit feature is not specified' do
      let(:params) { { info: { features: {} } } }

      it { is_expected.to be false }
    end

    context 'when features are not specified' do
      let(:params) { { info: {} } }

      it { is_expected.to be false }
    end

    context 'when info is not specified' do
      let(:params) { {} }

      it { is_expected.to be false }
    end
  end

  describe 'runner job acknowledgment support' do
    let!(:pending_job) { create(:ci_build, :pending, :queued, pipeline: pipeline) }

    subject(:execute) { service.execute(params) }

    context 'when runner supports two-phase job commit' do
      let(:params) do
        {
          info: {
            features: {
              two_phase_job_commit: true
            }
          }
        }
      end

      it 'assigns job to waiting state' do
        expect(Ci::RetryStuckWaitingJobWorker).to receive(:perform_in)
          .with(Gitlab::Ci::Build::RunnerAckQueue::RUNNER_ACK_QUEUE_EXPIRY_TIME, pending_job.id)

        result = execute

        expect(result).to be_valid
        expect(result.build).to eq(pending_job)
        expect(pending_job.reload).to be_pending
        expect(pending_job.queuing_entry).to be_nil
        expect(pending_job.runner_ack_wait_status).to eq(:waiting)
        expect(pending_job.runner_manager_id_waiting_for_ack).to eq(runner_manager.id)
      end

      it 'increments runner_assigned_waiting metric' do
        expect_next_instance_of(Gitlab::Ci::Queue::Metrics) do |metrics|
          allow(metrics).to receive(:increment_queue_operation)
          expect(metrics).to receive(:increment_queue_operation).with(:runner_assigned_waiting)
        end

        execute
      end

      context 'when allow_runner_job_acknowledgement feature flag is disabled' do
        before do
          stub_feature_flags(allow_runner_job_acknowledgement: false)
        end

        it 'assigns job to running state immediately' do
          result = execute

          expect(result).to be_valid
          expect(result.build).to eq(pending_job)
          expect(pending_job.reload).to be_running
          expect(pending_job.runner_ack_wait_status).to eq(:not_waiting)
          expect(pending_job.runner_manager).to eq(runner_manager)
        end

        it 'increments runner_assigned_run metric' do
          expect_next_instance_of(Gitlab::Ci::Queue::Metrics) do |metrics|
            allow(metrics).to receive(:increment_queue_operation)
            expect(metrics).to receive(:increment_queue_operation).with(:runner_assigned_run)
          end

          execute
        end
      end
    end

    context 'when runner does not support two-phase job commit' do
      let(:params) do
        {
          info: {
            features: {
              upload_multiple_artifacts: true
            }
          }
        }
      end

      it 'assigns job to running state immediately' do
        result = execute

        expect(result).to be_valid
        expect(result.build).to eq(pending_job)
        expect(pending_job.reload).to be_running
        expect(pending_job.runner_ack_wait_status).to eq(:not_waiting)
        expect(pending_job.runner_manager).to eq(runner_manager)
      end

      it 'increments runner_assigned_run metric' do
        expect_next_instance_of(Gitlab::Ci::Queue::Metrics) do |metrics|
          allow(metrics).to receive(:increment_queue_operation)
          expect(metrics).to receive(:increment_queue_operation).with(:runner_assigned_run)
        end

        execute
      end
    end

    context 'when params are missing info section' do
      let(:params) { {} }

      it 'assigns job to running state immediately' do
        result = execute

        expect(result).to be_valid
        expect(result.build).to eq(pending_job)
        expect(pending_job.reload).to be_running
        expect(pending_job.runner_ack_wait_status).to eq(:not_waiting)
        expect(pending_job.runner_manager).to eq(runner_manager)
      end
    end
  end
end
