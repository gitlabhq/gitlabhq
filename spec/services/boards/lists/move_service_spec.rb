require 'spec_helper'

describe Boards::Lists::MoveService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }

    it 'keeps position of lists when new position is nil' do
      list1 = create(:list, board: board, position: 1)
      list2 = create(:list, board: board, position: 2)
      list3 = create(:list, board: board, position: 3)
      list4 = create(:list, board: board, position: 4)
      list5 = create(:list, board: board, position: 5)

      service = described_class.new(project, { list_id: list2.id, position: nil })

      expect(service.execute).to eq false
      expect(list1.reload.position).to eq 1
      expect(list2.reload.position).to eq 2
      expect(list3.reload.position).to eq 3
      expect(list4.reload.position).to eq 4
      expect(list5.reload.position).to eq 5
    end

    it 'keeps position of lists when new positon is equal to old position' do
      list1 = create(:list, board: board, position: 1)
      list2 = create(:list, board: board, position: 2)
      list3 = create(:list, board: board, position: 3)
      list4 = create(:list, board: board, position: 4)
      list5 = create(:list, board: board, position: 5)

      service = described_class.new(project, { list_id: list2.id, position: 2 })

      expect(service.execute).to eq false
      expect(list1.reload.position).to eq 1
      expect(list2.reload.position).to eq 2
      expect(list3.reload.position).to eq 3
      expect(list4.reload.position).to eq 4
      expect(list5.reload.position).to eq 5
    end

    it 'decrements position of intermediate lists when new position is greater than old position' do
      list1 = create(:list, board: board, position: 1)
      list2 = create(:list, board: board, position: 2)
      list3 = create(:list, board: board, position: 3)
      list4 = create(:list, board: board, position: 4)
      list5 = create(:list, board: board, position: 5)

      service = described_class.new(project, { list_id: list2.id, position: 5 })

      expect(service.execute).to eq true
      expect(list1.reload.position).to eq 1
      expect(list2.reload.position).to eq 5
      expect(list3.reload.position).to eq 2
      expect(list4.reload.position).to eq 3
      expect(list5.reload.position).to eq 4
    end

    it 'increments position of intermediate lists when when new position is lower than old position' do
      list1 = create(:list, board: board, position: 1)
      list2 = create(:list, board: board, position: 2)
      list3 = create(:list, board: board, position: 3)
      list4 = create(:list, board: board, position: 4)
      list5 = create(:list, board: board, position: 5)

      service = described_class.new(project, { list_id: list5.id, position: 2 })

      expect(service.execute).to eq true
      expect(list1.reload.position).to eq 1
      expect(list2.reload.position).to eq 3
      expect(list3.reload.position).to eq 4
      expect(list4.reload.position).to eq 5
      expect(list5.reload.position).to eq 2
    end
  end
end
