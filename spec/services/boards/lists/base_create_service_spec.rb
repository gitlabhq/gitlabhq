# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::BaseCreateService, feature_category: :portfolio_management do
  let(:board) { create(:board) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(board, user) }

  describe '#reorder_subsequent_lists!' do
    let!(:list1) { create(:list, board: board, position: 0) }
    let!(:list2) { create(:list, board: board, position: 1) }
    let!(:list3) { create(:list, board: board, position: 2) }
    let!(:list4) { create(:list, board: board, position: 3) }

    it 'reorders lists correctly when inserting a new list' do
      insert_position = 1

      expect do
        service.send(:reorder_subsequent_lists!, board, insert_position)
      end.to change { board.lists.movable.reload.order(:position).pluck(:position) }
        .from([0, 1, 2, 3])
        .to([0, 2, 3, 4])

      expect(board.lists.movable.order(:position).pluck(:id, :position)).to eq([
        [list1.id, 0],
        [list2.id, 2],
        [list3.id, 3],
        [list4.id, 4]
      ])
    end

    it 'does not change positions when inserting at the end' do
      insert_position = 4

      expect do
        service.send(:reorder_subsequent_lists!, board, insert_position)
      end.not_to change { board.lists.movable.reload.order(:position).pluck(:position) }
    end
  end
end
