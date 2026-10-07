# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RedundantPipelines::CancelReplacedPipelineService, :clean_gitlab_redis_shared_state,
  feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project) }

  let!(:older_pipeline) { create(:ci_pipeline, :running, project: project, ref: 'main') }
  let!(:superseded_by) { create(:ci_pipeline, :running, project: project, ref: 'main', sha: 'newer-sha') }

  let(:ref_head_sha) { nil }
  let(:key) { Gitlab::Ci::RedundantPipelines::PipelineKey.of(older_pipeline) }

  subject(:execute) do
    described_class.for(key, superseded_by: superseded_by, ref_head_sha: ref_head_sha).execute
  end

  def cache
    Gitlab::Ci::RedundantPipelines::CandidateCache.for(project_id: project.id, ref: 'main')
  end

  describe '#execute' do
    let!(:job) { create(:ci_build, :interruptible, :running, pipeline: older_pipeline) }

    context 'when the newer pipeline replaces the older one' do
      it 'cancels it' do
        expect(execute).to be_success

        expect(job.reload).to be_canceled
      end

      it 'leaves it out of the cache' do
        execute

        expect(cache.size).to eq(0)
      end
    end

    shared_examples 'requeuing the older pipeline' do
      it 'leaves the older pipeline running' do
        expect(execute).to be_error
        expect(execute.reason).to eq(:pipeline_requeued)

        expect(job.reload).to be_running
      end

      it 'puts it back in the cache' do
        execute

        expect(cache).to be_registered(key)
      end
    end

    context 'when both pipelines are for the same commit' do
      before do
        superseded_by.update!(sha: older_pipeline.sha)
      end

      it_behaves_like 'requeuing the older pipeline'
    end

    context 'when the older pipeline is for the commit the ref points at' do
      let(:ref_head_sha) { older_pipeline.sha }

      it_behaves_like 'requeuing the older pipeline'
    end

    context 'when the older pipeline was created later' do
      before do
        older_pipeline.update!(created_at: superseded_by.created_at + 1.minute)
      end

      it_behaves_like 'requeuing the older pipeline'
    end

    shared_examples 'dropping the older pipeline' do
      it 'reports that it is dropped' do
        expect(execute).to be_error
        expect(execute.reason).to eq(:pipeline_dropped)
      end

      it 'does not put it back in the cache' do
        execute

        expect(cache.size).to eq(0)
      end
    end

    context 'when the older pipeline is gone' do
      let(:key) do
        Gitlab::Ci::RedundantPipelines::PipelineKey.new(non_existing_record_id, older_pipeline.partition_id)
      end

      it_behaves_like 'dropping the older pipeline'
    end

    context 'when the older pipeline has finished' do
      before do
        older_pipeline.update!(status: 'success')
      end

      it_behaves_like 'dropping the older pipeline'
    end
  end
end
