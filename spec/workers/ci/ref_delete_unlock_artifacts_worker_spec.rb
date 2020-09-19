# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RefDeleteUnlockArtifactsWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(project_id, user_id, ref) }

    let(:ref) { 'refs/heads/master' }

    let(:project) { create(:project) }

    include_examples 'an idempotent worker' do
      subject(:idempotent_perform) { perform_multiple([project_id, user_id, ref], exec_times: 2) }

      let(:project_id) { project.id }
      let(:user_id) { project.creator.id }

      let(:pipeline) { create(:ci_pipeline, ref: 'master', project: project, locked: :artifacts_locked) }

      it 'unlocks the artifacts from older pipelines' do
        expect { idempotent_perform }.to change { pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
      end
    end

    context 'when project exists' do
      let(:project_id) { project.id }

      context 'when user exists' do
        let(:user_id) { project.creator.id }

        context 'when ci ref exists for project' do
          let!(:ci_ref) { create(:ci_ref, ref_path: ref, project: project) }

          it 'calls the service' do
            service = spy(Ci::UnlockArtifactsService)
            expect(Ci::UnlockArtifactsService).to receive(:new).and_return(service)

            perform

            expect(service).to have_received(:execute).with(ci_ref)
          end
        end

        context 'when ci ref does not exist for the given project' do
          let!(:another_ci_ref) { create(:ci_ref, ref_path: ref) }

          it 'does not call the service' do
            expect(Ci::UnlockArtifactsService).not_to receive(:new)

            perform
          end
        end

        context 'when same ref path exists for a different project' do
          let!(:another_ci_ref) { create(:ci_ref, ref_path: ref) }
          let!(:ci_ref) { create(:ci_ref, ref_path: ref, project: project) }

          it 'calls the service with the correct ref_id' do
            service = spy(Ci::UnlockArtifactsService)
            expect(Ci::UnlockArtifactsService).to receive(:new).and_return(service)

            perform

            expect(service).to have_received(:execute).with(ci_ref)
          end
        end
      end

      context 'when user does not exist' do
        let(:user_id) { non_existing_record_id }

        it 'does not call service' do
          expect(Ci::UnlockArtifactsService).not_to receive(:new)

          perform
        end
      end
    end

    context 'when project does not exist' do
      let(:project_id) { non_existing_record_id }
      let(:user_id) { project.creator.id }

      it 'does not call service' do
        expect(Ci::UnlockArtifactsService).not_to receive(:new)

        perform
      end
    end
  end
end
