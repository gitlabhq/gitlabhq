require 'spec_helper'

describe Boards::Lists::DestroyService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }

    it 'removes list from board' do
      list = create(:list, board: board)
      service = described_class.new(project, list_id: list.id)

      expect { service.execute }.to change(board.lists, :count).by(-1)
    end

    it 'decrements position of higher lists' do
      list1 = create(:list, board: board, position: 1)
      list2 = create(:list, board: board, position: 2)
      list3 = create(:list, board: board, position: 3)
      list4 = create(:list, board: board, position: 4)
      list5 = create(:list, board: board, position: 5)

      described_class.new(project, list_id: list2.id).execute

      expect(list1.reload.position).to eq 1
      expect(list3.reload.position).to eq 2
      expect(list4.reload.position).to eq 3
      expect(list5.reload.position).to eq 4
    end
  end
end
