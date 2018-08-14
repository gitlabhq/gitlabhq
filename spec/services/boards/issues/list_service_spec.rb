require 'spec_helper'

describe Boards::Issues::ListService do
  describe '#execute' do
    context 'when parent is a project' do
      let(:user)    { create(:user) }
      let(:project) { create(:project) }
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
      let!(:reopened_issue1) { create(:issue, :opened, project: project, title: 'Issue 3' ) }

      let!(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, development]) }
      let!(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
      let!(:list1_issue3) { create(:labeled_issue, project: project, milestone: m1, labels: [development, p1]) }
      let!(:list2_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [testing]) }

      let!(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug]) }
      let!(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3]) }
      let!(:closed_issue3) { create(:issue, :closed, project: project) }
      let!(:closed_issue4) { create(:labeled_issue, :closed, project: project, labels: [p1]) }
      let!(:closed_issue5) { create(:labeled_issue, :closed, project: project, labels: [development]) }

      let(:parent) { project }

      before do
        project.add_developer(user)
      end

      it_behaves_like 'issues list service'
    end

    context 'when parent is a group' do
      let(:user)    { create(:user) }
      let(:project) { create(:project, :empty_repo, namespace: group) }
      let(:project1) { create(:project, :empty_repo, namespace: group) }

      let(:m1) { create(:milestone, group: group) }
      let(:m2) { create(:milestone, group: group) }

      let(:bug) { create(:group_label, group: group, name: 'Bug') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:testing)  { create(:group_label, group: group, name: 'Testing') }

      let(:p1) { create(:group_label, title: 'P1', group: group) }
      let(:p2) { create(:group_label, title: 'P2', group: group) }
      let(:p3) { create(:group_label, title: 'P3', group: group) }

      let(:p1_project) { create(:label, title: 'P1_project', project: project, priority: 1) }
      let(:p2_project) { create(:label, title: 'P2_project', project: project, priority: 2) }
      let(:p3_project) { create(:label, title: 'P3_project', project: project, priority: 3) }

      let(:p1_project1) { create(:label, title: 'P1_project1', project: project1, priority: 1) }
      let(:p2_project1) { create(:label, title: 'P2_project1', project: project1, priority: 2) }
      let(:p3_project1) { create(:label, title: 'P3_project1', project: project1, priority: 3) }

      let!(:backlog) { create(:backlog_list, board: board) }
      let!(:list1)   { create(:list, board: board, label: development, position: 0) }
      let!(:list2)   { create(:list, board: board, label: testing, position: 1) }
      let!(:closed)  { create(:closed_list, board: board) }

      let!(:opened_issue1) { create(:labeled_issue, project: project, milestone: m1, title: 'Issue 1', labels: [bug]) }
      let!(:opened_issue2) { create(:labeled_issue, project: project, milestone: m2, title: 'Issue 2', labels: [p2, p2_project]) }
      let!(:reopened_issue1) { create(:issue, state: 'opened', project: project, title: 'Issue 3', closed_at: Time.now ) }

      let!(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, p2_project, development]) }
      let!(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
      let!(:list1_issue3) { create(:labeled_issue, project: project1, milestone: m1, labels: [development, p1, p1_project1]) }
      let!(:list2_issue1) { create(:labeled_issue, project: project1, milestone: m1, labels: [testing]) }

      let!(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug]) }
      let!(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3, p3_project]) }
      let!(:closed_issue3) { create(:issue, :closed, project: project1) }
      let!(:closed_issue4) { create(:labeled_issue, :closed, project: project1, labels: [p1, p1_project1]) }
      let!(:closed_issue5) { create(:labeled_issue, :closed, project: project1, labels: [development]) }

      before do
        group.add_developer(user)
      end

      context 'and group has no parent' do
        let(:parent) { group }
        let(:group) { create(:group) }
        let(:board) { create(:board, group: group) }

        it_behaves_like 'issues list service'
      end

      context 'and group is an ancestor', :nested_groups do
        let(:parent) { create(:group) }
        let(:group) { create(:group, parent: parent) }
        let!(:backlog) { create(:backlog_list, board: board) }
        let(:board) { create(:board, group: parent) }

        before do
          parent.add_developer(user)
        end

        it_behaves_like 'issues list service'
      end
    end
  end
end
