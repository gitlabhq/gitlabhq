# frozen_string_literal: true

require 'spec_helper'

describe PipelineProcessWorker do
  describe '#perform' do
    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }

      it 'processes pipeline' do
        expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)

        described_class.new.perform(pipeline.id)
      end

      context 'when build_ids are passed' do
        let(:build) { create(:ci_build, pipeline: pipeline, name: 'my-build') }

        it 'processes pipeline with a list of builds' do
          expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)
            .with([build.id])

          described_class.new.perform(pipeline.id, [build.id])
        end
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
