require 'spec_helper'

describe Boards::DestroyService, services: true do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let!(:board)  { create(:board, project: project) }

    subject(:service) { described_class.new(project, double) }

    context 'when project have more than one board' do
      it 'removes board from project' do
        create(:board, project: project)

        expect { service.execute(board) }.to change(project.boards, :count).by(-1)
      end
    end

    context 'when project have one board' do
      it 'does not remove board from project' do
        expect { service.execute(board) }.not_to change(project.boards, :count)
      end
    end
  end
end
