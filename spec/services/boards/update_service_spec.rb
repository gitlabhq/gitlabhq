require 'spec_helper'

describe Boards::UpdateService do
  describe '#execute' do
    let(:project) { create(:empty_project) }
    let!(:board)  { create(:board, project: project, name: 'Backend') }

    it "updates board's name" do
      service = described_class.new(project, double, name: 'Engineering')

      service.execute(board)

      expect(board).to have_attributes(name: 'Engineering')
    end

    it 'returns true with valid params' do
      service = described_class.new(project, double, name: 'Engineering')

      expect(service.execute(board)).to eq true
    end

    it 'returns false with invalid params' do
      service = described_class.new(project, double, name: nil)

      expect(service.execute(board)).to eq false
    end

    it 'udpates the milestone with issue board milestones enabled' do
      stub_licensed_features(issue_board_milestone: true)
      milestone = create(:milestone, project: project)

      service = described_class.new(project, double, milestone_id: milestone.id)
      service.execute(board)

      expect(board.reload.milestone).to eq(milestone)
    end

    it 'udpates the milestone with the issue board milestones feature enabled' do
      stub_licensed_features(issue_board_milestone: false)
      milestone = create(:milestone, project: project)

      service = described_class.new(project, double, milestone_id: milestone.id)
      service.execute(board)

      expect(board.reload.milestone).to be_nil
    end
  end
end
