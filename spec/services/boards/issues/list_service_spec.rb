require 'spec_helper'

describe Boards::Issues::ListService, services: true do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:project) { create(:empty_project) }
    let(:board)   { create(:board, project: project) }

    let(:bug) { create(:label, project: project, name: 'Bug') }
    let(:development) { create(:label, project: project, name: 'Development') }
    let(:testing)  { create(:label, project: project, name: 'Testing') }
    let(:p1) { create(:label, title: 'P1', project: project, priority: 1) }
    let(:p2) { create(:label, title: 'P2', project: project, priority: 2) }
    let(:p3) { create(:label, title: 'P3', project: project, priority: 3) }

    let!(:backlog) { create(:backlog_list, board: board) }
    let!(:list1)   { create(:list, board: board, label: development, position: 0) }
    let!(:list2)   { create(:list, board: board, label: testing, position: 1) }
    let!(:done)    { create(:done_list, board: board) }

    let!(:opened_issue1) { create(:labeled_issue, project: project, labels: [bug]) }
    let!(:opened_issue2) { create(:labeled_issue, project: project, labels: [p2]) }
    let!(:reopened_issue1) { create(:issue, :reopened, project: project) }

    let!(:list1_issue1) { create(:labeled_issue, project: project, labels: [p2, development]) }
    let!(:list1_issue2) { create(:labeled_issue, project: project, labels: [development]) }
    let!(:list1_issue3) { create(:labeled_issue, project: project, labels: [development, p1]) }
    let!(:list2_issue1) { create(:labeled_issue, project: project, labels: [testing]) }

    let!(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug]) }
    let!(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3]) }
    let!(:closed_issue3) { create(:issue, :closed, project: project) }
    let!(:closed_issue4) { create(:labeled_issue, :closed, project: project, labels: [p1]) }

    before do
      project.team << [user, :developer]
    end

    it 'delegates search to IssuesFinder' do
      params = { board_id: board.id, id: list1.id }

      expect_any_instance_of(IssuesFinder).to receive(:execute).once.and_call_original

      described_class.new(project, user, params).execute
    end

    context 'sets default order to priority' do
      it 'returns opened issues when listing issues from Backlog' do
        params = { board_id: board.id, id: backlog.id }

        issues = described_class.new(project, user, params).execute

        expect(issues).to eq [opened_issue2, reopened_issue1, opened_issue1]
      end

      it 'returns closed issues when listing issues from Done' do
        params = { board_id: board.id, id: done.id }

        issues = described_class.new(project, user, params).execute

        expect(issues).to eq [closed_issue4, closed_issue2, closed_issue3, closed_issue1]
      end

      it 'returns opened issues that have label list applied when listing issues from a label list' do
        params = { board_id: board.id, id: list1.id }

        issues = described_class.new(project, user, params).execute

        expect(issues).to eq [list1_issue3, list1_issue1, list1_issue2]
      end
    end

    context 'with list that does not belong to the board' do
      it 'raises an error' do
        list = create(:list)
        service = described_class.new(project, user, board_id: board.id, id: list.id)

        expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with invalid list id' do
      it 'raises an error' do
        service = described_class.new(project, user, board_id: board.id, id: nil)

        expect { service.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
