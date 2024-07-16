# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RefDeleteUnlockArtifactsWorker, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#perform' do
    subject(:perform) { worker.perform(project_id, user_id, ref) }

    let(:worker) { described_class.new }
    let(:ref) { 'refs/heads/master' }
    let(:project) { create(:project) }
    let(:enqueue_pipelines_to_unlock_service_class) { Ci::Refs::EnqueuePipelinesToUnlockService }
    let(:enqueue_pipelines_to_unlock_service_instance_spy) { instance_double(Ci::Refs::EnqueuePipelinesToUnlockService) }

    context 'when project exists' do
      let(:project_id) { project.id }

      before do
        allow(enqueue_pipelines_to_unlock_service_class)
          .to receive(:new).and_return(enqueue_pipelines_to_unlock_service_instance_spy)
      end

      context 'when user exists' do
        let(:user_id) { project.creator.id }

        context 'when ci ref exists for project' do
          let!(:ci_ref) { create(:ci_ref, ref_path: ref, project: project) }

          it 'calls the enqueue pipelines to unlock service' do
            expect(worker).to receive(:log_extra_metadata_on_done).with(:total_pending_entries, 3)
            expect(worker).to receive(:log_extra_metadata_on_done).with(:total_new_entries, 2)

            expect(enqueue_pipelines_to_unlock_service_instance_spy)
              .to receive(:execute).with(ci_ref).and_return(total_pending_entries: 3, total_new_entries: 2)

            perform
          end
        end

        context 'when ci ref does not exist for the given project' do
          let!(:another_ci_ref) { create(:ci_ref, ref_path: ref) }

          it 'does not call the service' do
            expect(enqueue_pipelines_to_unlock_service_class).not_to receive(:new)

            perform
          end
        end

        context 'when same ref path exists for a different project' do
          let!(:another_ci_ref) { create(:ci_ref, ref_path: ref) }
          let!(:ci_ref) { create(:ci_ref, ref_path: ref, project: project) }

          it 'calls the enqueue pipelines to unlock service with the correct ref' do
            expect(enqueue_pipelines_to_unlock_service_instance_spy)
              .to receive(:execute).with(ci_ref).and_return(total_pending_entries: 3, total_new_entries: 2)

            perform
          end
        end
      end

      context 'when user does not exist' do
        let(:user_id) { non_existing_record_id }

        it 'does not call the service' do
          expect(enqueue_pipelines_to_unlock_service_class).not_to receive(:new)

          perform
        end
      end
    end

    context 'when project does not exist' do
      let(:project_id) { non_existing_record_id }
      let(:user_id) { project.creator.id }

      it 'does not call the service' do
        expect(enqueue_pipelines_to_unlock_service_class).not_to receive(:new)

        perform
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:project_id) { project.id }
      let(:user_id) { project.creator.id }
      let(:exec_times) { IdempotentWorkerHelper::WORKER_EXEC_TIMES }
      let(:job_args) { [project_id, user_id, ref] }

      let!(:ci_ref) { create(:ci_ref, ref_path: ref, project: project) }
      let!(:pipeline) { create(:ci_pipeline, ci_ref: ci_ref, project: project, locked: :artifacts_locked) }

      it 'enqueues all pipelines for the ref to be unlocked' do
        subject

        expect(pipeline_ids_waiting_to_be_unlocked).to eq([pipeline.id])
      end
    end
  end
end
