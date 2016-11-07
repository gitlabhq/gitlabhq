require 'spec_helper'

describe PipelineUnlockWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when locked pipelines are present' do
      context 'when multiple pipelines are locked in the last stage' do
        let(:created_pipeline) do
          create(:ci_pipeline, status: :created,
                               updated_at: 10.hours.ago)
        end

        let(:pending_pipeline) do
          create(:ci_pipeline, status: :pending,
                               updated_at: 10.hours.ago)
        end

        let(:running_pipeline) do
          create(:ci_pipeline, status: :running,
                               updated_at: 10.hours.ago)
        end

        before do
          create_build(created_pipeline, :pending, stage: 'test')
          create_build(pending_pipeline, :success, stage: 'test')
          create_build(running_pipeline, :failed, stage: 'test')
        end

        it 'updates each pipeline status' do
          expect(created_pipeline.reload).to be_created
          expect(pending_pipeline.reload).to be_pending
          expect(running_pipeline.reload).to be_running

          worker.perform

          expect(created_pipeline.reload).to be_pending
          expect(pending_pipeline.reload).to be_success
          expect(running_pipeline.reload).to be_failed
        end
      end

      context 'when locked pipeline has multiple stages ahead' do
        let(:pipeline) do
          create(:ci_pipeline, status: :running,
                               updated_at: 10.hours.ago)
        end

        before do
          create_build(pipeline, :success, stage: 'build', stage_idx: 1)
          create_build(pipeline, :created, stage: 'test', stage_idx: 2)
          create_build(pipeline, :created, stage: 'deploy', stage_idx: 3)
        end

        it 'retriggers pipeline processing' do
          expect(pipeline.reload).to be_running

          worker.perform

          expect(pipeline.reload).to be_running
          expect(find_build(pipeline, stage: 'test')).to be_pending
          expect(find_build(pipeline, stage: 'deploy')).to be_created
        end

        it 'updates pipeline' do
          expect { worker.perform }
            .to change { pipeline.reload.updated_at }
        end
      end
    end

    context 'when locked pipelines are not present' do
      context 'when there are fresh running pipelines' do
        before { create(:ci_pipeline, status: :running) }

        it 'does not trigger update' do
          expect_any_instance_of(PipelineProcessWorker)
            .not_to receive(:perform)
        end
      end

      context 'when there are no pipelines at all' do
        it 'does nothing' do
          expect_any_instance_of(PipelineProcessWorker)
            .not_to receive(:perform)
        end
      end
    end
  end

  def create_build(pipeline, status, opts = {})
    create(:ci_build, opts.merge(pipeline: pipeline, status: status))
  end

  def find_build(pipeline, opts)
    pipeline.builds.find_by(opts)
  end
end
