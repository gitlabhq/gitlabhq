# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RedundantPipelines::RegisterCandidateService, :clean_gitlab_redis_shared_state,
  feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project) }

  let(:pipeline) { create(:ci_pipeline, project: project, ref: 'main') }

  subject(:execute) { register(pipeline) }

  def cache
    Gitlab::Ci::RedundantPipelines::CandidateCache.for(project_id: project.id, ref: 'main')
  end

  def key(pipeline)
    Gitlab::Ci::RedundantPipelines::PipelineKey.of(pipeline)
  end

  def register(pipeline)
    described_class.for(pipeline).execute
  end

  describe '#execute' do
    it 'registers the pipeline for later pipelines' do
      execute

      expect(cache).to be_registered(key(pipeline))
    end

    it 'reports that it registered the pipeline' do
      expect(execute).to be_success
    end

    it 'asks for no cancellation, which the creation chain does' do
      expect(Ci::CancelRedundantPipelinesWorker).not_to receive(:perform_async)
      expect(Ci::LowUrgencyCancelRedundantPipelinesWorker).not_to receive(:perform_async)

      execute
    end

    it 'registers the same pipeline once, however often it is called' do
      execute
      execute

      expect(cache.size).to eq(1)
    end

    # Which pipelines a newer one may cancel is the policy's to answer, and its spec
    # covers every reason. This only has to leave the cache alone when the answer is no.
    context 'when no newer pipeline may cancel it' do
      before do
        pipeline.create_pipeline_metadata!(project: project, auto_cancel_on_new_commit: 'none')
      end

      it 'registers nothing and reports why' do
        expect(execute).to be_error
        expect(execute.reason).to eq(:pipeline_not_cancelable_by_newer_pipeline)

        expect(cache.size).to eq(0)
      end
    end
  end
end
