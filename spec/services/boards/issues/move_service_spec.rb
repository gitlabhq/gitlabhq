require 'spec_helper'

describe Boards::Issues::MoveService, services: true do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:project) { create(:project_with_board) }
    let(:board)   { project.board }

    let(:bug) { create(:label, project: project, name: 'Bug') }
    let(:development) { create(:label, project: project, name: 'Development') }
    let(:testing)  { create(:label, project: project, name: 'Testing') }

    let(:backlog) { create(:backlog_list, board: board) }
    let(:list1)   { create(:label_list, board: board, label: development) }
    let(:list2)   { create(:label_list, board: board, label: testing) }
    let(:done)    { create(:done_list, board: board) }

    before do
      project.team << [user, :developer]
    end

    context 'when moving from backlog' do
      it 'adds the label of the list it goes to' do
        issue = create(:labeled_issue, project: project, labels: [bug])
        params = { id: issue.iid, from: backlog.id, to: list1.id }

        described_class.new(project, user, params).execute

        expect(issue.reload.labels).to contain_exactly(bug, development)
      end
    end

    context 'when moving to backlog' do
      it 'remove the label of the list it came from' do
        issue = create(:labeled_issue, project: project, labels: [bug, development])
        params = { id: issue.iid, from: list1.id, to: backlog.id }

        described_class.new(project, user, params).execute

        expect(issue.reload.labels).to contain_exactly(bug)
      end
    end

    context 'when moving from backlog to done' do
      it 'closes the issue' do
        issue = create(:labeled_issue, project: project, labels: [bug])
        params = { id: issue.iid, from: backlog.id, to: done.id }

        described_class.new(project, user, params).execute
        issue.reload

        expect(issue.labels).to contain_exactly(bug)
        expect(issue).to be_closed
      end
    end

    context 'when moving an issue between lists' do
      let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development]) }
      let(:params) { { id: issue.iid, from: list1.id, to: list2.id } }

      it 'delegates the label changes to Issues::UpdateService' do
        expect_any_instance_of(Issues::UpdateService).to receive(:execute).with(issue).once

        described_class.new(project, user, params).execute
      end

      it 'removes the label from the list it came from and adds the label of the list it goes to' do
        described_class.new(project, user, params).execute

        expect(issue.reload.labels).to contain_exactly(bug, testing)
      end
    end

    context 'when moving to done' do
      let(:issue)  { create(:labeled_issue, project: project, labels: [bug, testing]) }
      let(:params) { { id: issue.iid, from: list2.id, to: done.id } }

      it 'delegates the close proceedings to Issues::CloseService' do
        expect_any_instance_of(Issues::CloseService).to receive(:execute).with(issue).once

        described_class.new(project, user, params).execute
      end

      it 'remove the label of the list it came from and close the issue' do
        described_class.new(project, user, params).execute
        issue.reload

        expect(issue.labels).to contain_exactly(bug)
        expect(issue).to be_closed
      end
    end

    context 'when moving from done' do
      let(:issue)  { create(:labeled_issue, :closed, project: project, labels: [bug]) }
      let(:params) { { id: issue.iid, from: done.id, to: list2.id } }

      it 'delegates the re-open proceedings to Issues::ReopenService' do
        expect_any_instance_of(Issues::ReopenService).to receive(:execute).with(issue).once

        described_class.new(project, user, params).execute
      end

      it 'adds the label of the list it goes to and reopen the issue' do
        described_class.new(project, user, params).execute
        issue.reload

        expect(issue.labels).to contain_exactly(bug, testing)
        expect(issue).to be_reopened
      end
    end

    context 'when moving from done to backlog' do
      it 'reopens the issue' do
        issue = create(:labeled_issue, :closed, project: project, labels: [bug])
        params = { id: issue.iid, from: done.id, to: backlog.id }

        described_class.new(project, user, params).execute
        issue.reload

        expect(issue.labels).to contain_exactly(bug)
        expect(issue).to be_reopened
      end
    end
  end
end
