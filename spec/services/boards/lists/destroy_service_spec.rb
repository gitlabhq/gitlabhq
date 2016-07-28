require 'spec_helper'

describe Boards::Lists::DestroyService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }

    context 'when list type is label' do
      it 'removes list from board' do
        list = create(:label_list, board: board)
        service = described_class.new(project, list_id: list.id)

        expect { service.execute }.to change(board.lists, :count).by(-1)
      end

      it 'decrements position of higher lists' do
        list1 = create(:backlog_list, board: board, position: 1)
        list2 = create(:label_list, board: board, position: 2)
        list3 = create(:label_list, board: board, position: 3)
        list4 = create(:label_list, board: board, position: 4)
        list5 = create(:done_list, board: board, position: 5)

        described_class.new(project, list_id: list2.id).execute

        expect(list1.reload.position).to eq 1
        expect(list3.reload.position).to eq 2
        expect(list4.reload.position).to eq 3
        expect(list5.reload.position).to eq 4
      end
    end

    it 'does not remove list from board when list type is backlog' do
      list = create(:backlog_list, board: board)
      service = described_class.new(project, list_id: list.id)

      expect { service.execute }.not_to change(board.lists, :count)
    end

    it 'does not remove list from board when list type is done' do
      list = create(:done_list, board: board)
      service = described_class.new(project, list_id: list.id)

      expect { service.execute }.not_to change(board.lists, :count)
    end
  end
end
