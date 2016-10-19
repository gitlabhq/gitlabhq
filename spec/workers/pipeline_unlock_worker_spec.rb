require 'spec_helper'

describe PipelineUnlockWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when locked pipelines are present' do
      let(:pipeline) do
        create(:ci_pipeline, status: :running,
                             updated_at: 10.hours.ago)
      end

      context 'when pipeline is locked in the last stage' do
        before do
          create_build(status: :success, stage: 'test')
        end

        it 'updates pipeline status to finished' do
          expect(pipeline.reload).to be_running

          worker.perform

          expect(pipeline.reload).to be_success
        end
      end

      context 'when locked pipeline has multiple stages ahead' do
        before do
          create_build(status: :success, stage: 'build', stage_idx: 1)
          create_build(status: :created, stage: 'test', stage_idx: 2)
          create_build(status: :created, stage: 'deploy', stage_idx: 3)
        end

        it 'retriggers pipeline processing' do
          expect(pipeline.reload).to be_running

          worker.perform

          expect(pipeline.reload).to be_running
          expect(find_build(stage: 'test')).to be_pending
          expect(find_build(stage: 'deploy')).to be_created
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

  def create_build(opts)
    create(:ci_build, opts.merge(pipeline: pipeline))
  end

  def find_build(opts)
    pipeline.builds.find_by(opts)
  end
end
