require 'spec_helper'

describe PipelineMetricsWorker do
  let(:project) { create(:project) }
  let!(:merge_request) { create(:merge_request, source_project: project, source_branch: pipeline.ref) }

  let(:pipeline) do
    create(:ci_empty_pipeline,
           status: status,
           project: project,
           ref: 'master',
           sha: project.repository.commit('master').id,
           started_at: 1.hour.ago,
           finished_at: Time.now)
  end

  describe '#perform' do
    subject { described_class.new.perform(pipeline.id) }

    context 'when pipeline is running' do
      let(:status) { 'running' }

      it 'records the build start time' do
        subject

        expect(merge_request.reload.metrics.latest_build_started_at).to be_within(1.second).of(pipeline.started_at)
      end

      it 'clears the build end time' do
        subject

        expect(merge_request.reload.metrics.latest_build_finished_at).to be_nil
      end
    end

    context 'when pipeline succeeded' do
      let(:status) { 'success' }

      it 'records the build end time' do
        subject

        expect(merge_request.reload.metrics.latest_build_finished_at).to be_within(1.second).of(pipeline.finished_at)
      end
    end
  end
end
