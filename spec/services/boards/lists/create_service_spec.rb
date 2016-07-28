require 'spec_helper'

describe Boards::Lists::CreateService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:label)   { create(:label, name: 'in-progress') }

    subject(:service) { described_class.new(project, label_id: label.id) }

    context 'when board lists is empty' do
      it 'creates a new list at begginning of the list' do
        list = service.execute

        expect(list.position).to eq 0
      end
    end

    context 'when board lists has a backlog list' do
      it 'creates a new list at end of the list' do
        create(:backlog_list, board: board, position: 0)

        list = service.execute

        expect(list.position).to eq 1
      end
    end

    context 'when board lists are only labels lists' do
      it 'creates a new list at end of the list' do
        create_list(:label_list, 2, board: board)

        list = described_class.new(project, label_id: label.id).execute

        expect(list.position).to eq 3
      end
    end

    context 'when board lists has a done list' do
      it 'creates a new list before' do
        list1 = create(:backlog_list, board: board, position: 1)
        list2 = create(:label_list, board: board, position: 2)
        list3 = create(:done_list, board: board, position: 3)

        list = described_class.new(project, label_id: label.id).execute

        expect(list.position).to eq 3
        expect(list1.reload.position).to eq 1
        expect(list2.reload.position).to eq 2
        expect(list3.reload.position).to eq 4
      end
    end
  end
end
