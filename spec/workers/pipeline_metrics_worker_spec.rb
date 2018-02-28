require 'spec_helper'

describe PipelineMetricsWorker do
  let(:project) { create(:project, :repository) }

  let!(:merge_request) do
    create(:merge_request, source_project: project,
                           source_branch: pipeline.ref,
                           head_pipeline: pipeline)
  end

  let(:pipeline) do
    create(:ci_empty_pipeline,
           status: status,
           project: project,
           ref: 'master',
           sha: project.repository.commit('master').id,
           started_at: 1.hour.ago,
           finished_at: Time.now)
  end

  let(:status) { 'pending' }

  describe '#perform' do
    before do
      described_class.new.perform(pipeline.id)
    end

    context 'when pipeline is running' do
      let(:status) { 'running' }

      it 'records the build start time' do
        expect(merge_request.reload.metrics.latest_build_started_at).to be_like_time(pipeline.started_at)
      end

      it 'clears the build end time' do
        expect(merge_request.reload.metrics.latest_build_finished_at).to be_nil
      end

      it 'records the pipeline' do
        expect(merge_request.reload.metrics.pipeline).to eq(pipeline)
      end
    end

    context 'when pipeline succeeded' do
      let(:status) { 'success' }

      it 'records the build end time' do
        expect(merge_request.reload.metrics.latest_build_finished_at).to be_like_time(pipeline.finished_at)
      end

      it 'records the pipeline' do
        expect(merge_request.reload.metrics.pipeline).to eq(pipeline)
      end
    end
  end
end
