# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineProcessWorker do
  describe '#perform' do
    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline) }

      it 'processes pipeline' do
        expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)

        described_class.new.perform(pipeline.id)
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end

    it_behaves_like 'worker with data consistency',
                described_class,
                feature_flag: :load_balancing_for_pipeline_process_worker,
                data_consistency: :delayed
  end
end
