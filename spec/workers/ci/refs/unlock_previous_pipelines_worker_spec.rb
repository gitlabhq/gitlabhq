# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Refs::UnlockPreviousPipelinesWorker, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  let!(:older_pipeline) do
    create(
      :ci_pipeline,
      :with_persisted_artifacts,
      :artifacts_locked
    )
  end

  let!(:pipeline) do
    create(
      :ci_pipeline,
      :with_persisted_artifacts,
      :artifacts_locked,
      ref: older_pipeline.ref,
      tag: older_pipeline.tag,
      project: older_pipeline.project
    )
  end

  describe '#perform' do
    it 'executes a service' do
      ci_ref = pipeline.ci_ref
      expect(ci_ref).to receive(:last_unlockable_ci_source_pipeline).and_return(pipeline)

      expect(Ci::Ref).to receive(:find_by_id).with(pipeline.ci_ref.id).and_return(ci_ref)

      expect_next_instance_of(Ci::Refs::EnqueuePipelinesToUnlockService) do |instance|
        expect(instance).to receive(:execute).with(ci_ref, before_pipeline: pipeline).and_call_original
      end

      worker.perform(pipeline.ci_ref.id)
    end

    context 'when ref has no pipelines locked' do
      before do
        older_pipeline.update!(locked: :unlocked)
        pipeline.update!(locked: :unlocked)
      end

      it 'does nothing' do
        expect(Ci::Refs::EnqueuePipelinesToUnlockService).not_to receive(:new)

        worker.perform(pipeline.ci_ref.id)
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { pipeline.ci_ref.id }

    it 'only enqueues IDs of older pipelines if they are not in the queue' do
      expect { subject }
        .to change { pipeline_ids_waiting_to_be_unlocked }
        .from([])
        .to([older_pipeline.id])
    end
  end
end
