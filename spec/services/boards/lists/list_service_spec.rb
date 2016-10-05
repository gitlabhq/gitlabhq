require 'spec_helper'

describe Boards::Lists::ListService, services: true do
  describe '#execute' do
    it "returns board's lists" do
      project = create(:empty_project)
      board = create(:board, project: project)
      label = create(:label, project: project)
      backlog_list = create(:backlog_list, board: board)
      list = create(:list, board: board, label: label)
      done_list = create(:done_list, board: board)

      service = described_class.new(project, double)

      expect(service.execute(board)).to eq [backlog_list, list, done_list]
    end
  end
end
