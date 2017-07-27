require 'spec_helper'

describe Boards::ListService do
  describe '#execute' do
    let(:project) { create(:empty_project) }

    subject(:service) { described_class.new(project, double) }

    context 'when project does not have a board' do
      it 'creates a new project board' do
        expect { service.execute }.to change(project.boards, :count).by(1)
      end

      it 'delegates the project board creation to Boards::CreateService' do
        expect_any_instance_of(Boards::CreateService).to receive(:execute).once

        service.execute
      end
    end

    context 'when project has a board' do
      before do
        create(:board, project: project)
      end

      it 'does not create a new board' do
        expect { service.execute }.not_to change(project.boards, :count)
      end
    end

    it 'returns project boards' do
      board1 = create(:board, project: project)
      board2 = create(:board, project: project)

      expect(service.execute).to match_array [board1, board2]
    end
  end
end
