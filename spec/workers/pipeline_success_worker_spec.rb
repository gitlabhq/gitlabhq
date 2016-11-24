require 'spec_helper'

describe PipelineSuccessWorker do
  describe '#perform' do
    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline, status: 'success') }

      it 'performs "merge when pipeline succeeds"' do
        expect_any_instance_of(
          MergeRequests::MergeWhenBuildSucceedsService
        ).to receive(:trigger)

        described_class.new.perform(pipeline.id)
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
