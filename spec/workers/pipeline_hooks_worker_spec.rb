# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineHooksWorker do
  describe '#perform' do
    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }

      it 'executes hooks for the pipeline' do
        hook_service = double

        expect(Ci::Pipelines::HookService).to receive(:new).and_return(hook_service)
        expect(hook_service).to receive(:execute)

        described_class.new.perform(pipeline.id)
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise exception' do
        expect(Ci::Pipelines::HookService).not_to receive(:new)

        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end

  it_behaves_like 'worker with data consistency',
                  described_class,
                  data_consistency: :delayed
end
