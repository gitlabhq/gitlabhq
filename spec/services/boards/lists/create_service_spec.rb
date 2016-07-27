require 'spec_helper'

describe Boards::Lists::CreateService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:label)   { create(:label, name: 'in-progress') }

    it 'creates a new list for board' do
      service = described_class.new(project, label_id: label.id)

      expect { service.execute }.to change(board.lists, :count).by(1)
    end

    it 'inserts the list to the end of lists' do
      create_list(:list, 2, board: board)
      service = described_class.new(project, label_id: label.id)

      list = service.execute

      expect(list.position).to eq 2
    end
  end
end
