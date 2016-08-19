require 'spec_helper'

describe Boards::Lists::GenerateService, services: true do
  describe '#execute' do
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }
    let(:user)    { create(:user) }

    subject(:service) { described_class.new(project, user) }

    context 'when board lists is empty' do
      it 'creates the default lists' do
        expect { service.execute }.to change(board.lists, :count).by(4)
      end
    end

    context 'when board lists is not empty' do
      it 'does not creates the default lists' do
        create(:list, board: board)

        expect { service.execute }.not_to change(board.lists, :count)
      end
    end

    context 'when project labels does not contains any list label' do
      it 'creates labels' do
        expect { service.execute }.to change(project.labels, :count).by(4)
      end
    end

    context 'when project labels contains some of list label' do
      it 'creates the missing labels' do
        create(:label, project: project, name: 'Development')
        create(:label, project: project, name: 'Ready')

        expect { service.execute }.to change(project.labels, :count).by(2)
      end
    end
  end
end
