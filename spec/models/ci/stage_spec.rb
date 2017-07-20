require 'spec_helper'

describe Ci::Stage, :models do
  let(:stage) { create(:ci_stage_entity) }

  describe 'associations' do
    before do
      create(:ci_build, stage_id: stage.id)
      create(:commit_status, stage_id: stage.id)
    end

    describe '#commit_statuses' do
      it 'returns all commit statuses' do
        expect(stage.commit_statuses.count).to be 2
      end
    end

    describe '#builds' do
      it 'returns only builds' do
        expect(stage.builds).to be_one
      end
    end
  end

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

  describe 'update!' do
    context 'when stage objects needs to be updated' do
      before do
        create(:ci_build, :success, stage_id: stage.id)
        create(:ci_build, :running, stage_id: stage.id)
      end

      it 'updates stage status correctly' do
        expect { stage.update! }
          .to change { stage.reload.status }
          .to 'running'
      end
    end

    context 'when stage object is locked' do
    end
  end
end
