require 'spec_helper'

describe Boards::Lists::MoveService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let!(:list1)  { create(:backlog_list, board: board, position: 1) }
    let!(:list2)  { create(:label_list,   board: board, position: 2) }
    let!(:list3)  { create(:label_list,   board: board, position: 3) }
    let!(:list4)  { create(:label_list,   board: board, position: 4) }
    let!(:list5)  { create(:label_list,   board: board, position: 5) }
    let!(:list6)  { create(:done_list,    board: board, position: 6) }

    context 'when list type is set to label' do
      it 'keeps position of lists when new position is nil' do
        service = described_class.new(project, { list_id: list2.id, position: nil })

        service.execute

        expect(positions_of_lists).to eq [1, 2, 3, 4, 5, 6]
      end

      it 'keeps position of lists when new positon is equal to old position' do
        service = described_class.new(project, { list_id: list2.id, position: 2 })

        service.execute

        expect(positions_of_lists).to eq [1, 2, 3, 4, 5, 6]
      end

      it 'keeps position of lists when new positon is equal to first position' do
        service = described_class.new(project, { list_id: list3.id, position: 1 })

        service.execute

        expect(positions_of_lists).to eq [1, 2, 3, 4, 5, 6]
      end

      it 'keeps position of lists when new positon is equal to last position' do
        service = described_class.new(project, { list_id: list3.id, position: 6 })

        service.execute

        expect(positions_of_lists).to eq [1, 2, 3, 4, 5, 6]
      end

      it 'decrements position of intermediate lists when new position is greater than old position' do
        service = described_class.new(project, { list_id: list2.id, position: 5 })

        service.execute

        expect(positions_of_lists).to eq [1, 5, 2, 3, 4, 6]
      end

      it 'increments position of intermediate lists when when new position is lower than old position' do
        service = described_class.new(project, { list_id: list5.id, position: 2 })

        service.execute

        expect(positions_of_lists).to eq [1, 3, 4, 5, 2, 6]
      end
    end

    it 'keeps position of lists when list type is backlog' do
      service = described_class.new(project, { list_id: list1.id, position: 2 })

      service.execute

      expect(positions_of_lists).to eq [1, 2, 3, 4, 5, 6]
    end

    it 'keeps position of lists when list type is done' do
      service = described_class.new(project, { list_id: list6.id, position: 2 })

      service.execute

      expect(positions_of_lists).to eq [1, 2, 3, 4, 5, 6]
    end
  end

  def positions_of_lists
    (1..6).map { |index| send("list#{index}").reload.position }
  end
end
