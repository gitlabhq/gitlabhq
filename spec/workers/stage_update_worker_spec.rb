require 'spec_helper'

describe StageUpdateWorker do
  describe '#perform' do
    context 'when stage exists' do
      let(:stage) { create(:ci_stage_entity) }

      it 'updates stage status' do
        expect_any_instance_of(Ci::Stage).to receive(:update_status)

        described_class.new.perform(stage.id)
      end
    end

    context 'when stage does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
