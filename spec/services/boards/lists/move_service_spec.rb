require 'spec_helper'

describe Boards::Lists::MoveService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:user)    { create(:user) }

    let!(:backlog)     { create(:backlog_list, board: board) }
    let!(:planning)    { create(:list, board: board, position: 1) }
    let!(:development) { create(:list, board: board, position: 2) }
    let!(:review)      { create(:list, board: board, position: 3) }
    let!(:staging)     { create(:list, board: board, position: 4) }
    let!(:done)        { create(:done_list, board: board) }

    context 'when list type is set to label' do
      it 'keeps position of lists when new position is nil' do
        service = described_class.new(project, user, id: planning.id, position: nil)

        service.execute

        expect(current_list_positions).to eq [1, 2, 3, 4]
      end

      it 'keeps position of lists when new positon is equal to old position' do
        service = described_class.new(project, user, id: planning.id, position: 1)

        service.execute

        expect(current_list_positions).to eq [1, 2, 3, 4]
      end

      it 'keeps position of lists when new positon is negative' do
        service = described_class.new(project, user, id: planning.id, position: -1)

        service.execute

        expect(current_list_positions).to eq [1, 2, 3, 4]
      end

      it 'keeps position of lists when new positon is greater than number of labels lists' do
        service = described_class.new(project, user, id: planning.id, position: 6)

        service.execute

        expect(current_list_positions).to eq [1, 2, 3, 4]
      end

      it 'increments position of intermediate lists when new positon is equal to first position' do
        service = described_class.new(project, user, id: staging.id, position: 1)

        service.execute

        expect(current_list_positions).to eq [2, 3, 4, 1]
      end

      it 'decrements position of intermediate lists when new positon is equal to last position' do
        service = described_class.new(project, user, id: planning.id, position: 4)

        service.execute

        expect(current_list_positions).to eq [4, 1, 2, 3]
      end

      it 'decrements position of intermediate lists when new position is greater than old position' do
        service = described_class.new(project, user, id: planning.id, position: 3)

        service.execute

        expect(current_list_positions).to eq [3, 1, 2, 4]
      end

      it 'increments position of intermediate lists when new position is lower than old position' do
        service = described_class.new(project, user, id: staging.id, position: 2)

        service.execute

        expect(current_list_positions).to eq [1, 3, 4, 2]
      end
    end

    it 'keeps position of lists when list type is backlog' do
      service = described_class.new(project, user, id: backlog.id, position: 2)

      service.execute

      expect(current_list_positions).to eq [1, 2, 3, 4]
    end

    it 'keeps position of lists when list type is done' do
      service = described_class.new(project, user, id: done.id, position: 2)

      service.execute

      expect(current_list_positions).to eq [1, 2, 3, 4]
    end
  end

  def current_list_positions
    [planning, development, review, staging].map { |list| list.reload.position }
  end
end
