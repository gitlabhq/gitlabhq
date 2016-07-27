require 'spec_helper'

describe Boards::CreateService, services: true do
  describe '#execute' do
    it 'creates a new board when project does not has one' do
      project = create(:empty_project, board: nil)
      service = described_class.new(project)

      expect { service.execute }.to change(Board, :count).by(1)
    end

    it 'returns project board when project has one' do
      project = create(:project_with_board)
      service = described_class.new(project)

      expect(service.execute).to eq project.board
    end
  end
end
