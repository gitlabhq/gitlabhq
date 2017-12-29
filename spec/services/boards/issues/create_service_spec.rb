require 'spec_helper'

describe Boards::Issues::CreateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }
    let!(:list)   { create(:list, board: board, label: label, position: 0) }

    subject(:service) { described_class.new(board.parent, project, user, board_id: board.id, list_id: list.id, title: 'New issue') }

    before do
      project.add_developer(user)
    end

    it 'delegates the create proceedings to Issues::CreateService' do
      expect_any_instance_of(Issues::CreateService).to receive(:execute).once

      service.execute
    end

    it 'creates a new issue' do
      expect { service.execute }.to change(project.issues, :count).by(1)
    end

    it 'adds the label of the list to the issue' do
      issue = service.execute

      expect(issue.labels).to eq [label]
    end

    it 'adds the board assignee, weight, labels and milestone to the issue' do
      board_assignee = create(:user)
      project.add_developer(board_assignee)
      board_milestone = create(:milestone, project: project)
      board_label = create(:label, project: project)
      board.update!(assignee: board_assignee,
                    milestone: board_milestone,
                    label_ids: [board_label.id],
                    weight: 4)

      issue = service.execute

      expect(issue.assignees).to eq([board_assignee])
      expect(issue.weight).to eq(board.weight)
      expect(issue.milestone).to eq(board_milestone)
      expect(issue.labels).to contain_exactly(label, board_label)
    end
  end
end
