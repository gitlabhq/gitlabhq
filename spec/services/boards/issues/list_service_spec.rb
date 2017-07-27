require 'spec_helper'

describe Boards::Issues::ListService do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:project) { create(:empty_project) }
    let(:board)   { create(:board, project: project) }

    let(:m1) { create(:milestone, project: project) }
    let(:m2) { create(:milestone, project: project) }

    let(:bug) { create(:label, project: project, name: 'Bug') }
    let(:development) { create(:label, project: project, name: 'Development') }
    let(:testing)  { create(:label, project: project, name: 'Testing') }
    let(:p1) { create(:label, title: 'P1', project: project, priority: 1) }
    let(:p2) { create(:label, title: 'P2', project: project, priority: 2) }
    let(:p3) { create(:label, title: 'P3', project: project, priority: 3) }

    let!(:backlog) { create(:backlog_list, board: board) }
    let!(:list1)   { create(:list, board: board, label: development, position: 0) }
    let!(:list2)   { create(:list, board: board, label: testing, position: 1) }
    let!(:closed)  { create(:closed_list, board: board) }

    let!(:opened_issue1) { create(:labeled_issue, project: project, milestone: m1, title: 'Issue 1', labels: [bug]) }
    let!(:opened_issue2) { create(:labeled_issue, project: project, milestone: m2, title: 'Issue 2', labels: [p2]) }
    let!(:reopened_issue1) { create(:issue, :reopened, project: project, title: 'Issue 3' ) }

    let!(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, development]) }
    let!(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
    let!(:list1_issue3) { create(:labeled_issue, project: project, milestone: m1, labels: [development, p1]) }
    let!(:list2_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [testing]) }

    let!(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug]) }
    let!(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3]) }
    let!(:closed_issue3) { create(:issue, :closed, project: project) }
    let!(:closed_issue4) { create(:labeled_issue, :closed, project: project, labels: [p1]) }
    let!(:closed_issue5) { create(:labeled_issue, :closed, project: project, labels: [development]) }

    before do
      project.team << [user, :developer]
    end

    it 'delegates search to IssuesFinder' do
      params = { board_id: board.id, id: list1.id }

      expect_any_instance_of(IssuesFinder).to receive(:execute).once.and_call_original

      described_class.new(project, user, params).execute
    end

    context 'when list_id is missing' do
      context 'when board does not have a milestone' do
        it 'returns opened issues without board labels applied' do
          params = { board_id: board.id }

          issues = described_class.new(project, user, params).execute

          expect(issues).to eq [opened_issue2, reopened_issue1, opened_issue1]
        end
      end

      context 'when board have a milestone' do
        it 'returns opened issues without board labels and milestone applied' do
          params = { board_id: board.id }
          board.update_attribute(:milestone, m1)

          issues = described_class.new(project, user, params).execute

          expect(issues).to eq [opened_issue2, list1_issue2, reopened_issue1, opened_issue1]
        end
      end
    end

    context 'issues are ordered by priority' do
      it 'returns opened issues when list_id is missing' do
        params = { board_id: board.id }

        issues = described_class.new(project, user, params).execute

        expect(issues).to eq [opened_issue2, reopened_issue1, opened_issue1]
      end

      it 'returns opened issues when listing issues from Backlog' do
        params = { board_id: board.id, id: backlog.id }

        issues = described_class.new(project, user, params).execute

        expect(issues).to eq [opened_issue2, reopened_issue1, opened_issue1]
      end

      it 'returns closed issues when listing issues from Closed' do
        params = { board_id: board.id, id: closed.id }

        issues = described_class.new(project, user, params).execute

        expect(issues).to eq [closed_issue4, closed_issue2, closed_issue5, closed_issue3, closed_issue1]
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
