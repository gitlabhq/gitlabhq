# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StageUpdateWorker, feature_category: :continuous_integration do
  describe '#perform' do
    context 'when stage exists' do
      let(:stage) { create(:ci_stage) }

      it 'updates stage status' do
        expect_any_instance_of(Ci::Stage).to receive(:set_status).with('skipped')

        described_class.new.perform(stage.id)
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [stage.id] }

        it 'results in the stage getting the skipped status' do
          expect { subject }.to change { stage.reload.status }.from('pending').to('skipped')
          expect { subject }.not_to change { stage.reload.status }
        end
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
