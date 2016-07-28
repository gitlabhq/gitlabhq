require 'spec_helper'

describe Boards::CreateService, services: true do
  describe '#execute' do
    subject(:service) { described_class.new(project) }

    context 'when project does not have a board' do
      let(:project) { create(:empty_project, board: nil) }

      it 'creates a new board' do
        expect { service.execute }.to change(Board, :count).by(1)
      end

      it 'creates default lists' do
        service.execute

        expect(project.board.lists.size).to eq 2
        expect(project.board.lists.first).to be_backlog
        expect(project.board.lists.last).to be_done
      end
    end

    context 'when project has a board' do
      let!(:project) { create(:project_with_board) }

      it 'does not create a new board' do
        expect { service.execute }.not_to change(Board, :count)
      end

      it 'does not create board lists' do
        expect { service.execute }.not_to change(project.board.lists, :count)
      end
    end
  end
end
