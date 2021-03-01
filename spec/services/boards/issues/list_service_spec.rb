# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Issues::ListService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    context 'when parent is a project' do
      let_it_be(:project) { create(:project, :empty_repo) }
      let_it_be(:board)   { create(:board, project: project) }

      let_it_be(:m1) { create(:milestone, project: project) }
      let_it_be(:m2) { create(:milestone, project: project) }

      let_it_be(:bug) { create(:label, project: project, name: 'Bug') }
      let_it_be(:development) { create(:label, project: project, name: 'Development') }
      let_it_be(:testing) { create(:label, project: project, name: 'Testing') }
      let_it_be(:p1) { create(:label, title: 'P1', project: project, priority: 1) }
      let_it_be(:p2) { create(:label, title: 'P2', project: project, priority: 2) }
      let_it_be(:p3) { create(:label, title: 'P3', project: project, priority: 3) }

      let_it_be(:backlog) { create(:backlog_list, board: board) }
      let_it_be(:list1)   { create(:list, board: board, label: development, position: 0) }
      let_it_be(:list2)   { create(:list, board: board, label: testing, position: 1) }
      let_it_be(:closed)  { create(:closed_list, board: board) }

      let_it_be(:opened_issue1) { create(:labeled_issue, project: project, milestone: m1, title: 'Issue 1', labels: [bug]) }
      let_it_be(:opened_issue2) { create(:labeled_issue, project: project, milestone: m2, title: 'Issue 2', labels: [p2]) }
      let_it_be(:reopened_issue1) { create(:issue, :opened, project: project, title: 'Reopened Issue 1' ) }

      let_it_be(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, development]) }
      let_it_be(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
      let_it_be(:list1_issue3) { create(:labeled_issue, project: project, milestone: m1, labels: [development, p1]) }
      let_it_be(:list2_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [testing]) }

      let_it_be(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug], closed_at: 1.day.ago) }
      let_it_be(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3], closed_at: 2.days.ago) }
      let_it_be(:closed_issue3) { create(:issue, :closed, project: project, closed_at: 1.week.ago) }
      let_it_be(:closed_issue4) { create(:labeled_issue, :closed, project: project, labels: [p1], closed_at: 1.year.ago) }
      let_it_be(:closed_issue5) { create(:labeled_issue, :closed, project: project, labels: [development], closed_at: 2.years.ago) }

      let(:parent) { project }

      before do
        project.add_developer(user)
      end

      it_behaves_like 'issues list service'

      context 'when project is archived' do
        before do
          project.update!(archived: true)
        end

        it_behaves_like 'issues list service'
      end
    end

    # rubocop: disable RSpec/MultipleMemoizedHelpers
    context 'when parent is a group' do
      let(:project) { create(:project, :empty_repo, namespace: group) }
      let(:project1) { create(:project, :empty_repo, namespace: group) }
      let(:project_archived) { create(:project, :empty_repo, :archived, namespace: group) }

      let(:m1) { create(:milestone, group: group) }
      let(:m2) { create(:milestone, group: group) }

      let(:bug) { create(:group_label, group: group, name: 'Bug') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:testing) { create(:group_label, group: group, name: 'Testing') }

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
      let!(:opened_issue3) { create(:labeled_issue, project: project_archived, milestone: m1, title: 'Issue 3', labels: [bug]) }
      let!(:reopened_issue1) { create(:issue, state: 'opened', project: project, title: 'Reopened Issue 1', closed_at: Time.current ) }

      let!(:list1_issue1) { create(:labeled_issue, project: project, milestone: m1, labels: [p2, p2_project, development]) }
      let!(:list1_issue2) { create(:labeled_issue, project: project, milestone: m2, labels: [development]) }
      let!(:list1_issue3) { create(:labeled_issue, project: project1, milestone: m1, labels: [development, p1, p1_project1]) }
      let!(:list2_issue1) { create(:labeled_issue, project: project1, milestone: m1, labels: [testing]) }

      let!(:closed_issue1) { create(:labeled_issue, :closed, project: project, labels: [bug], closed_at: 1.day.ago) }
      let!(:closed_issue2) { create(:labeled_issue, :closed, project: project, labels: [p3, p3_project], closed_at: 2.days.ago) }
      let!(:closed_issue3) { create(:issue, :closed, project: project1, closed_at: 1.week.ago) }
      let!(:closed_issue4) { create(:labeled_issue, :closed, project: project1, labels: [p1, p1_project1], closed_at: 1.year.ago) }
      let!(:closed_issue5) { create(:labeled_issue, :closed, project: project1, labels: [development], closed_at: 2.years.ago) }

      before do
        group.add_developer(user)
      end

      context 'when the group has no parent' do
        let(:parent) { group }
        let(:group) { create(:group) }
        let(:board) { create(:board, group: group) }

        it_behaves_like 'issues list service'
      end

      context 'when the group is an ancestor' do
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
    # rubocop: enable RSpec/MultipleMemoizedHelpers
  end
end
