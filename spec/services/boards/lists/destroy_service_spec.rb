require 'spec_helper'

describe Boards::Lists::DestroyService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:user)    { create(:user) }

    context 'when list type is label' do
      it 'removes list from board' do
        list = create(:list, board: board)
        service = described_class.new(project, user)

        expect { service.execute(list) }.to change(board.lists, :count).by(-1)
      end

      it 'decrements position of higher lists' do
        backlog     = project.board.backlog_list
        development = create(:list, board: board, position: 0)
        review      = create(:list, board: board, position: 1)
        staging     = create(:list, board: board, position: 2)
        done        = project.board.done_list

        described_class.new(project, user).execute(development)

        expect(backlog.reload.position).to be_nil
        expect(review.reload.position).to eq 0
        expect(staging.reload.position).to eq 1
        expect(done.reload.position).to be_nil
      end
    end

    it 'does not remove list from board when list type is backlog' do
      list = project.board.backlog_list
      service = described_class.new(project, user)

      expect { service.execute(list) }.not_to change(board.lists, :count)
    end

    it 'does not remove list from board when list type is done' do
      list = project.board.done_list
      service = described_class.new(project, user)

      expect { service.execute(list) }.not_to change(board.lists, :count)
    end
  end
end
