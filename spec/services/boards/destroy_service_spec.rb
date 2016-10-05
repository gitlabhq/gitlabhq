require 'spec_helper'

describe Boards::DestroyService, services: true do
  describe '#execute' do
    it 'removes board from project' do
      project = create(:empty_project)
      board   = create(:board, project: project)

      service = described_class.new(project, double)

      expect { service.execute(board) }.to change(project.boards, :count).by(-1)
    end
  end
end
