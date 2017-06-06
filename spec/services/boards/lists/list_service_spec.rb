require 'spec_helper'

describe Boards::Lists::ListService, services: true do
  let(:project) { create(:empty_project) }
  let(:board) { create(:board, project: project) }
  let(:label) { create(:label, project: project) }
  let!(:list) { create(:list, board: board, label: label) }
  let(:service) { described_class.new(project, double) }

  describe '#execute' do
    context 'when the board has a backlog list' do
      before do
        create(:backlog_list, board: board)
      end

      it 'does not create a backlog list' do
        service.execute(board)

        expect(board.lists.merge(List.backlog)).to eq [board.backlog_list]
      end

      it "returns board's lists" do
        expect(service.execute(board)).to eq [board.backlog_list, list, board.closed_list]
      end
    end

    context 'when the board does not have a backlog list' do
      it 'creates a backlog list' do
        service.execute(board)

        expect(board.backlog_list).not_to be nil
      end

      it "returns board's lists" do
        expect(service.execute(board)).to eq [board.backlog_list, list, board.closed_list]
      end
    end
  end
end
