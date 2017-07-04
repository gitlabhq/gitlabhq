require 'spec_helper'

describe Ci::Stage, :models do
  describe '#status' do
    context 'when stage is pending' do
      let(:stage) { create(:ci_stage_entity, status: 'pending') }

      it 'has a correct status value' do
        expect(stage.status).to eq 'pending'
      end
    end

    context 'when stage is success' do
      let(:stage) { create(:ci_stage_entity, status: 'success') }

      it 'has a correct status value' do
        expect(stage.status).to eq 'success'
      end
    end
  end
end
