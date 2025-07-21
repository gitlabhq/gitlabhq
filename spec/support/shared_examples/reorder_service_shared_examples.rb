# frozen_string_literal: true

RSpec.shared_examples 'reorder service' do
  context 'when reordering items' do
    context 'when no params are passed' do
      let(:params) { {} }

      it 'does not reorder' do
        expect { service_result }
          .not_to change { work_item.relative_position }

        expect(service_result[:errors])
          .to eq(["At least one of move_before_id or move_after_id is required"])
      end
    end

    context 'with both invalid params' do
      let(:params) { { move_after_id: nil, move_before_id: non_existing_record_id } }

      it 'does not reorder' do
        expect { service_result }
          .not_to change { work_item.relative_position }

        expect(service_result[:errors]).to eq(["Work item not found"])
      end
    end

    context 'with valid params' do
      let(:params) { { move_after_id: item2.id, move_before_id: item3.id } }

      it 'sorts items' do
        expect { service_result }
          .to change { work_item.relative_position }.to be_between(
            item2.relative_position,
            item3.relative_position
          )

        expect(service_result[:errors]).to be_empty
      end
    end

    context 'when only move_before_id is given' do
      let(:params) { { move_before_id: item3.id } }

      it 'sorts items if only given one neighbour, on the left' do
        expect { service_result }
          .to change { work_item.relative_position }.to be > item3.relative_position

        expect(service_result[:errors]).to be_empty
      end
    end

    context 'when only move_after_id is given' do
      let(:work_item) { item3 }
      let(:params) { { move_after_id: item1.id } }

      it 'sorts items if only given one neighbour, on the right' do
        expect { service_result }
          .to change { work_item.relative_position }.to be < item1.relative_position

        expect(service_result[:errors]).to be_empty
      end
    end
  end
end
