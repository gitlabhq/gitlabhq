require 'spec_helper'

describe Boards::Lists::CreateService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:label)   { create(:label, name: 'in-progress') }

    subject(:service) { described_class.new(project, label_id: label.id) }

    context 'when board lists is empty' do
      it 'creates a new list at beginning of the list' do
        list = service.execute

        expect(list.position).to eq 1
      end
    end

    context 'when board lists has only a backlog list' do
      it 'creates a new list at beginning of the list' do
        create(:backlog_list, board: board)

        list = service.execute

        expect(list.position).to eq 1
      end
    end

    context 'when board lists has only labels lists' do
      it 'creates a new list at end of the lists' do
        create(:label_list, board: board, position: 1)
        create(:label_list, board: board, position: 2)

        list = described_class.new(project, label_id: label.id).execute

        expect(list.position).to eq 3
      end
    end

    context 'when board lists has backlog, label and done lists' do
      it 'creates a new list at end of the label lists' do
        create(:backlog_list, board: board)
        create(:done_list, board: board)
        list1 = create(:label_list, board: board, position: 1)

        list2 = described_class.new(project, label_id: label.id).execute

        expect(list1.reload.position).to eq 1
        expect(list2.reload.position).to eq 2
      end
    end
  end
end
