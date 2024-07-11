# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockPipelineService, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#execute', :aggregate_failures do
    let(:service) { described_class.new(pipeline) }

    let!(:pipeline) do
      create(
        :ci_pipeline,
        :with_coverage_report_artifact,
        :with_codequality_mr_diff_report,
        :with_persisted_artifacts,
        locked: :artifacts_locked
      )
    end

    subject(:execute) { service.execute }

    context 'when pipeline is not yet exclusively leased' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      it 'unlocks the pipeline and all its artifacts' do
        expect { execute }
          .to change { pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
          .and change { pipeline.reload.job_artifacts.all?(&:artifact_unlocked?) }.to(true)
          .and change { pipeline.reload.pipeline_artifacts.all?(&:artifact_unlocked?) }.to(true)

        expect(execute).to eq(
          status: :success,
          skipped_already_leased: false,
          skipped_already_unlocked: false,
          exec_timeout: false,
          unlocked_job_artifacts: pipeline.job_artifacts.count,
          unlocked_pipeline_artifacts: pipeline.pipeline_artifacts.count
        )
      end

      context 'when disable_ci_partition_pruning is disabled' do
        before do
          stub_feature_flags(disable_ci_partition_pruning: false)
        end

        it 'unlocks the pipeline and all its artifacts' do
          expect { execute }
            .to change { pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
            .and change { pipeline.reload.job_artifacts.all?(&:artifact_unlocked?) }.to(true)
            .and change { pipeline.reload.pipeline_artifacts.all?(&:artifact_unlocked?) }.to(true)

          expect(execute).to eq(
            status: :success,
            skipped_already_leased: false,
            skipped_already_unlocked: false,
            exec_timeout: false,
            unlocked_job_artifacts: pipeline.job_artifacts.count,
            unlocked_pipeline_artifacts: pipeline.pipeline_artifacts.count
          )
        end
      end

      context 'and pipeline is already unlocked' do
        before do
          described_class.new(pipeline).execute
        end

        it 'skips the pipeline' do
          expect(Ci::JobArtifact).not_to receive(:where)

          expect(execute).to eq(
            status: :success,
            skipped_already_leased: false,
            skipped_already_unlocked: true,
            exec_timeout: false,
            unlocked_job_artifacts: 0,
            unlocked_pipeline_artifacts: 0
          )
        end
      end

      context 'and max execution duration was reached' do
        let!(:first_artifact) { pipeline.job_artifacts.order(:id).first }
        let!(:last_artifact) { pipeline.job_artifacts.order(:id).last }

        before do
          stub_const("#{described_class}::MAX_EXEC_DURATION", 0.seconds)
        end

        it 'keeps the unlocked state of job artifacts already processed and re-enqueues the pipeline' do
          expect { execute }
            .to change { first_artifact.reload.artifact_unlocked? }.to(true)
            .and not_change { last_artifact.reload.artifact_unlocked? }
            .and not_change { pipeline.reload.locked }
            .and not_change { pipeline.reload.pipeline_artifacts.all?(&:artifact_unlocked?) }
            .and change { pipeline_ids_waiting_to_be_unlocked }.from([]).to([pipeline.id])

          expect(execute).to eq(
            status: :success,
            skipped_already_leased: false,
            skipped_already_unlocked: false,
            exec_timeout: true,
            unlocked_job_artifacts: 1,
            unlocked_pipeline_artifacts: 0
          )
        end
      end

      context 'and an error happened' do
        context 'and was raised in the middle batches of job artifacts being unlocked' do
          let!(:first_artifact) { pipeline.job_artifacts.order(:id).first }
          let!(:last_artifact) { pipeline.job_artifacts.order(:id).last }

          before do
            mock_relation = instance_double('Ci::JobArtifact::ActiveRecord_Relation')
            allow(Ci::JobArtifact).to receive(:where).and_call_original
            allow(Ci::JobArtifact).to receive(:where)
                                        .with(id: [last_artifact.id], partition_id: last_artifact.partition_id)
                                        .and_return(mock_relation)
            allow(mock_relation).to receive(:update_all).and_raise('An error')
          end

          it 'keeps the unlocked state of job artifacts already processed and re-enqueues the pipeline' do
            expect { execute }
              .to raise_error('An error')
              .and change { first_artifact.reload.artifact_unlocked? }.to(true)
              .and not_change { last_artifact.reload.artifact_unlocked? }
              .and not_change { pipeline.reload.locked }
              .and not_change { pipeline.reload.pipeline_artifacts.all?(&:artifact_unlocked?) }
              .and change { pipeline_ids_waiting_to_be_unlocked }.from([]).to([pipeline.id])
          end
        end

        context 'and was raised while unlocking pipeline artifacts' do
          before do
            allow(pipeline).to receive_message_chain(:pipeline_artifacts, :update_all).and_raise('An error')
          end

          it 'keeps the unlocked state of job artifacts and re-enqueues the pipeline' do
            expect { execute }
              .to raise_error('An error')
              .and change { pipeline.reload.job_artifacts.all?(&:artifact_unlocked?) }.to(true)
              .and not_change { Ci::PipelineArtifact.where(pipeline_id: pipeline.id).all?(&:artifact_unlocked?) }
              .and not_change { pipeline.reload.locked }.from('artifacts_locked')
              .and change { pipeline_ids_waiting_to_be_unlocked }.from([]).to([pipeline.id])
          end
        end

        context 'and was raised while unlocking pipeline' do
          before do
            allow(pipeline).to receive(:update_column).and_raise('An error')
          end

          it 'keeps the unlocked state of job artifacts and pipeline artifacts and re-enqueues the pipeline' do
            expect { execute }
              .to raise_error('An error')
              .and change { pipeline.reload.job_artifacts.all?(&:artifact_unlocked?) }.to(true)
              .and change { pipeline.reload.pipeline_artifacts.all?(&:artifact_unlocked?) }.to(true)
              .and not_change { pipeline.reload.locked }.from('artifacts_locked')
              .and change { pipeline_ids_waiting_to_be_unlocked }.from([]).to([pipeline.id])
          end
        end
      end
    end

    context 'when pipeline is already exclusively leased' do
      before do
        allow(service).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end

      it 'does nothing and returns success' do
        expect { execute }.not_to change { pipeline.reload.locked }

        expect(execute).to include(
          status: :success,
          skipped_already_leased: true,
          unlocked_job_artifacts: 0,
          unlocked_pipeline_artifacts: 0
        )
      end
    end
  end
end
