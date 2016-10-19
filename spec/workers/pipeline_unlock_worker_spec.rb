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
          expect(pipeline.reload.status).to eq 'running'

          worker.perform

          expect(pipeline.reload.status).to eq 'success'
        end
      end

      context 'when locked pipeline has multiple stages ahead' do
        before do
          create_build(status: :success, stage: 'build', stage_idx: 1)
          create_build(status: :created, stage: 'test', stage_idx: 2)
          create_build(status: :created, stage: 'deploy', stage_idx: 3)
        end

        it 'retriggers pipeline processing' do
          expect(pipeline.reload.status).to eq 'running'

          worker.perform

          expect(pipeline.reload.status).to eq 'running'
          expect(pipeline.builds.find_by(stage: 'test').status)
            .to eq 'pending'
          expect(pipeline.builds.find_by(stage: 'deploy').status)
            .to eq 'created'
        end

        it 'updates pipeline' do
          expect { worker.perform }
            .to change { pipeline.reload.updated_at }
        end
      end
    end

    context 'when locked pipelines are not present' do
      context 'when there are fresh running pipelines' do
      end

      context 'when there are no pipelines at all' do
        it 'does nothing' do
        end
      end
    end
  end

  def create_build(opts)
    create(:ci_build, opts.merge(pipeline: pipeline))
  end
end
