require 'spec_helper'

describe Boards::UpdateService do
  describe '#execute' do
    let(:project) { create(:project) }
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

    it 'updates the configuration params when scoped issue board is enabled' do
      stub_licensed_features(scoped_issue_board: true)
      assignee = create(:user)
      milestone = create(:milestone, project: project)
      label = create(:label, project: project)

      service = described_class.new(project, double,
                                    milestone_id: milestone.id,
                                    assignee_id: assignee.id,
                                    label_ids: [label.id])
      service.execute(board)

      expect(board.reload).to have_attributes(milestone: milestone,
                                              assignee: assignee,
                                              labels: [label])
    end

    it 'filters unpermitted params when scoped issue board is not enabled' do
      stub_licensed_features(scoped_issue_board: false)
      params = { milestone_id: double, assignee_id: double, label_ids: double, weight: double }

      service = described_class.new(project, double, params)
      service.execute(board)

      expect(board.reload).to have_attributes(milestone: nil,
                                              assignee: nil,
                                              labels: [])
    end
  end
end
