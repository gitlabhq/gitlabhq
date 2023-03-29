# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockRefArtifactsOnPipelineStopWorker, feature_category: :build_artifacts do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline_id) }

    include_examples 'an idempotent worker' do
      subject(:idempotent_perform) { perform_multiple(pipeline.id, exec_times: 2) }

      let!(:older_pipeline) do
        create(:ci_pipeline, :success, :with_job, locked: :artifacts_locked).tap do |pipeline|
          create(:ci_job_artifact, job: pipeline.builds.first)
        end
      end

      let!(:pipeline) do
        create(:ci_pipeline, :success, :with_job, ref: older_pipeline.ref, tag: older_pipeline.tag,
          project: older_pipeline.project, locked: :unlocked).tap do |pipeline|
          create(:ci_job_artifact, job: pipeline.builds.first)
        end
      end

      it 'unlocks the artifacts from older pipelines' do
        expect { idempotent_perform }.to change { older_pipeline.reload.locked }.from('artifacts_locked').to('unlocked')
      end
    end

    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline, :success, :with_job) }
      let(:pipeline_id) { pipeline.id }

      it 'calls the Ci::UnlockArtifactsService with the ref and pipeline' do
        expect_next_instance_of(Ci::UnlockArtifactsService) do |service|
          expect(service).to receive(:execute).with(pipeline.ci_ref, pipeline).and_call_original
        end

        perform
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not call the service' do
        expect(Ci::UnlockArtifactsService).not_to receive(:new)

        perform
      end
    end

    context 'when the ref no longer exists' do
      let(:pipeline) { create(:ci_pipeline, :success, :with_job, ci_ref_presence: false) }
      let(:pipeline_id) { pipeline.id }

      it 'does not call the service' do
        expect(Ci::UnlockArtifactsService).not_to receive(:new)

        perform
      end
    end
  end
end
