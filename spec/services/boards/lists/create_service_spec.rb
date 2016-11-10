require 'spec_helper'

describe Boards::Lists::CreateService, services: true do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }

    subject(:service) { described_class.new(project, user, label_id: label.id) }

    before do
      project.team << [user, :developer]
    end

    context 'when board lists is empty' do
      it 'creates a new list at beginning of the list' do
        list = service.execute(board)

        expect(list.position).to eq 0
      end
    end

    context 'when board lists has backlog, and done lists' do
      it 'creates a new list at beginning of the list' do
        list = service.execute(board)

        expect(list.position).to eq 0
      end
    end

    context 'when board lists has labels lists' do
      it 'creates a new list at end of the lists' do
        create(:list, board: board, position: 0)
        create(:list, board: board, position: 1)

        list = service.execute(board)

        expect(list.position).to eq 2
      end
    end

    context 'when board lists has backlog, label and done lists' do
      it 'creates a new list at end of the label lists' do
        list1 = create(:list, board: board, position: 0)

        list2 = service.execute(board)

        expect(list1.reload.position).to eq 0
        expect(list2.reload.position).to eq 1
      end
    end

    context 'when provided label does not belongs to the project' do
      it 'raises an error' do
        label = create(:label, name: 'in-development')
        service = described_class.new(project, user, label_id: label.id)

        expect { service.execute(board) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
