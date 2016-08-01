require 'spec_helper'

describe Boards::Lists::DestroyService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }

    context 'when list type is label' do
      it 'removes list from board' do
        list = create(:list, board: board)
        service = described_class.new(project, list_id: list.id)

        expect { service.execute }.to change(board.lists, :count).by(-1)
      end

      it 'decrements position of higher lists' do
        backlog     = create(:backlog_list, board: board)
        development = create(:list, board: board, position: 1)
        review      = create(:list, board: board, position: 2)
        staging     = create(:list, board: board, position: 3)
        done        = create(:done_list, board: board)

        described_class.new(project, list_id: development.id).execute

        expect(backlog.reload.position).to be_nil
        expect(review.reload.position).to eq 1
        expect(staging.reload.position).to eq 2
        expect(done.reload.position).to be_nil
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
