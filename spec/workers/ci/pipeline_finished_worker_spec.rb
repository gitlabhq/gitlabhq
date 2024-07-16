# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineFinishedWorker, '#perform', feature_category: :continuous_integration do
  subject(:perform) { described_class.new.perform(pipeline.id) }

  context 'when pipeline exists' do
    let_it_be_with_refind(:project) { create(:project) }
    let_it_be_with_refind(:pipeline) do
      create(:ci_pipeline, :success, user: create(:user), project: project, finished_at: 1.second.ago)
    end

    it 'saves pipeline on Ci::FinishedPipelineChSyncEvent by default' do
      expect { perform }.to change { Ci::FinishedPipelineChSyncEvent.all }
        .from([])
        .to([an_object_having_attributes(pipeline_id: pipeline.id, pipeline_finished_at: pipeline.finished_at,
          project_namespace_id: pipeline.project.project_namespace_id)])
    end

    context 'when pipeline has already been processed' do
      before do
        described_class.new.perform(pipeline.id)

        Ci::FinishedPipelineChSyncEvent.pending.first.update!(processed: true)
      end

      it 'ignores duplicate calls for same pipeline' do
        perform

        expect(Ci::FinishedPipelineChSyncEvent.all).to contain_exactly(
          an_object_having_attributes(
            pipeline_id: pipeline.id, pipeline_finished_at: pipeline.finished_at,
            project_namespace_id: pipeline.project.project_namespace_id, processed: true)
        )
      end
    end

    context 'when project is scheduled for deletion' do
      before do
        project.update!(pending_delete: true)
      end

      it 'does not save pipeline on Ci::FinishedPipelineChSyncEvent' do
        expect { perform }.not_to change { Ci::FinishedPipelineChSyncEvent.count }
      end
    end

    context 'when pipeline does not have finished_at value' do
      before do
        pipeline.update!(finished_at: nil)
      end

      it 'does not save pipeline on Ci::FinishedPipelineChSyncEvent' do
        expect { perform }.not_to change { Ci::FinishedPipelineChSyncEvent.count }
      end
    end
  end

  context 'when pipeline does not exist' do
    it 'does not raise exception' do
      expect { described_class.new.perform(non_existing_record_id) }
        .not_to raise_error
    end
  end
end
