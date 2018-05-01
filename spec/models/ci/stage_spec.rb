require 'spec_helper'

describe Ci::Stage, :models do
  let(:stage) { create(:ci_stage_entity) }

  describe 'associations' do
    before do
      create(:ci_build, stage_id: stage.id)
      create(:commit_status, stage_id: stage.id)
    end

    describe '#statuses' do
      it 'returns all commit statuses' do
        expect(stage.statuses.count).to be 2
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

    context 'when stage status is not defined' do
      before do
        stage.update_column(:status, nil)
      end

      it 'sets the default value' do
        expect(described_class.find(stage.id).status)
          .to eq 'created'
      end
    end
  end

  describe '#update_status' do
    context 'when stage objects needs to be updated' do
      before do
        create(:ci_build, :success, stage_id: stage.id)
        create(:ci_build, :running, stage_id: stage.id)
      end

      it 'updates stage status correctly' do
        expect { stage.update_status }
          .to change { stage.reload.status }
          .to 'running'
      end
    end

    context 'when stage is skipped' do
      it 'updates status to skipped' do
        expect { stage.update_status }
          .to change { stage.reload.status }
          .to 'skipped'
      end
    end

    context 'when stage object is locked' do
      before do
        create(:ci_build, :failed, stage_id: stage.id)
      end

      it 'retries a lock to update a stage status' do
        stage.lock_version = 100

        stage.update_status

        expect(stage.reload).to be_failed
      end
    end
  end

  describe '#index' do
    context 'when stage has been imported and does not have position index set' do
      before do
        stage.update_column(:position, nil)
      end

      context 'when stage has statuses' do
        before do
          create(:ci_build, :running, stage_id: stage.id, stage_idx: 10)
        end

        it 'recalculates index before updating status' do
          expect(stage.reload.position).to be_nil

          stage.update_status

          expect(stage.reload.position).to eq 10
        end
      end

      context 'when stage does not have statuses' do
        it 'fallbacks to zero' do
          expect(stage.reload.position).to be_nil

          stage.update_status

          expect(stage.reload.position).to eq 0
        end
      end
    end
  end
end
