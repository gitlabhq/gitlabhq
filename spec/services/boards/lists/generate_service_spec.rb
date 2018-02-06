require 'spec_helper'

describe Boards::Lists::GenerateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }

    subject(:service) { described_class.new(project, user) }

    before do
      project.add_developer(user)
    end

    context 'when board lists is empty' do
      it 'creates the default lists' do
        expect { service.execute(board) }.to change(board.lists, :count).by(2)
      end
    end

    context 'when board lists is not empty' do
      it 'does not creates the default lists' do
        create(:list, board: board)

        expect { service.execute(board) }.not_to change(board.lists, :count)
      end
    end

    context 'when project labels does not contains any list label' do
      it 'creates labels' do
        expect { service.execute(board) }.to change(project.labels, :count).by(2)
      end
    end

    context 'when project labels contains some of list label' do
      it 'creates the missing labels' do
        create(:label, project: project, name: 'Doing')

        expect { service.execute(board) }.to change(project.labels, :count).by(1)
      end
    end
  end
end
