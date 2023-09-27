# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Refs::UnlockPreviousPipelinesWorker, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :build_artifacts do
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
      ref: older_pipeline.ref,
      tag: older_pipeline.tag,
      project: older_pipeline.project
    )
  end

  describe '#perform' do
    it 'executes a service' do
      expect_next_instance_of(Ci::Refs::EnqueuePipelinesToUnlockService) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      worker.perform(pipeline.ci_ref.id)
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
