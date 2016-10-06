require 'spec_helper'

describe Boards::Lists::ListService, services: true do
  describe '#execute' do
    it "returns board's lists" do
      project = create(:empty_project)
      board = create(:board, project: project)
      label = create(:label, project: project)
      list = create(:list, board: board, label: label)

      service = described_class.new(project, double)

      expect(service.execute(board)).to eq [board.backlog_list, list, board.done_list]
    end
  end
end
