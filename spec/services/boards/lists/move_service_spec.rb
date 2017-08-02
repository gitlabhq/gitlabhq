require 'spec_helper'

describe Boards::Lists::MoveService do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }

    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }
    let!(:review)      { create(:list, board: board, position: 2) }
    let!(:staging)     { create(:list, board: board, position: 3) }
    let!(:closed)      { create(:closed_list, board: board) }

    context 'when list type is set to label' do
      it 'keeps position of lists when new position is nil' do
        service = described_class.new(project, user, position: nil)

        service.execute(planning)

        expect(current_list_positions).to eq [0, 1, 2, 3]
      end

      it 'keeps position of lists when new positon is equal to old position' do
        service = described_class.new(project, user, position: planning.position)

        service.execute(planning)

        expect(current_list_positions).to eq [0, 1, 2, 3]
      end

      it 'keeps position of lists when new positon is negative' do
        service = described_class.new(project, user, position: -1)

        service.execute(planning)

        expect(current_list_positions).to eq [0, 1, 2, 3]
      end

      it 'keeps position of lists when new positon is equal to number of labels lists' do
        service = described_class.new(project, user, position: board.lists.label.size)

        service.execute(planning)

        expect(current_list_positions).to eq [0, 1, 2, 3]
      end

      it 'keeps position of lists when new positon is greater than number of labels lists' do
        service = described_class.new(project, user, position: board.lists.label.size + 1)

        service.execute(planning)

        expect(current_list_positions).to eq [0, 1, 2, 3]
      end

      it 'increments position of intermediate lists when new positon is equal to first position' do
        service = described_class.new(project, user, position: 0)

        service.execute(staging)

        expect(current_list_positions).to eq [1, 2, 3, 0]
      end

      it 'decrements position of intermediate lists when new positon is equal to last position' do
        service = described_class.new(project, user, position: board.lists.label.last.position)

        service.execute(planning)

        expect(current_list_positions).to eq [3, 0, 1, 2]
      end

      it 'decrements position of intermediate lists when new position is greater than old position' do
        service = described_class.new(project, user, position: 2)

        service.execute(planning)

        expect(current_list_positions).to eq [2, 0, 1, 3]
      end

      it 'increments position of intermediate lists when new position is lower than old position' do
        service = described_class.new(project, user, position: 1)

        service.execute(staging)

        expect(current_list_positions).to eq [0, 2, 3, 1]
      end
    end

    it 'keeps position of lists when list type is closed' do
      service = described_class.new(project, user, position: 2)

      service.execute(closed)

      expect(current_list_positions).to eq [0, 1, 2, 3]
    end
  end

  def current_list_positions
    [planning, development, review, staging].map { |list| list.reload.position }
  end
end
