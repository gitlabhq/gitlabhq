# frozen_string_literal: true

require 'spec_helper'

describe Issuable::BulkUpdateService do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  def bulk_update(issuables, extra_params = {})
    bulk_update_params = extra_params
      .reverse_merge(issuable_ids: Array(issuables).map(&:id).join(','))

    type = Array(issuables).first.model_name.param_key
    Issuable::BulkUpdateService.new(parent, user, bulk_update_params).execute(type)
  end

  shared_examples 'updates milestones' do
    it 'succeeds' do
      result = bulk_update(issuables, milestone_id: milestone.id)

      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(issuables.count)
    end

    it 'updates the issuables milestone' do
      bulk_update(issuables, milestone_id: milestone.id)

      issuables.each do |issuable|
        expect(issuable.reload.milestone).to eq(milestone)
      end
    end
  end

  shared_examples 'updating labels' do
    def create_issue_with_labels(labels)
      create(:labeled_issue, project: project, labels: labels)
    end

    let(:issue_all_labels) { create_issue_with_labels([bug, regression, merge_requests]) }
    let(:issue_bug_and_regression) { create_issue_with_labels([bug, regression]) }
    let(:issue_bug_and_merge_requests) { create_issue_with_labels([bug, merge_requests]) }
    let(:issue_no_labels) { create(:issue, project: project) }
    let(:issues) { [issue_all_labels, issue_bug_and_regression, issue_bug_and_merge_requests, issue_no_labels] }

    let(:labels) { [] }
    let(:add_labels) { [] }
    let(:remove_labels) { [] }

    let(:bulk_update_params) do
      {
        label_ids:        labels.map(&:id),
        add_label_ids:    add_labels.map(&:id),
        remove_label_ids: remove_labels.map(&:id)
      }
    end

    before do
      bulk_update(issues, bulk_update_params)
    end

    context 'when label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_no_labels] }
      let(:labels) { [bug, regression] }

      it 'updates the labels of all issues passed to the labels passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(match_array(labels.map(&:id)))
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end

      context 'when those label IDs are empty' do
        let(:labels) { [] }

        it 'updates the issues passed to have no labels' do
          expect(issues.map(&:reload).map(&:label_ids)).to all(be_empty)
        end
      end
    end

    context 'when add_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_merge_requests, issue_no_labels] }
      let(:add_labels) { [bug, regression, merge_requests] }

      it 'adds those label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(*add_labels.map(&:id)))
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end

    context 'when remove_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_merge_requests, issue_no_labels] }
      let(:remove_labels) { [bug, regression, merge_requests] }

      it 'removes those label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(be_empty)
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end

    context 'when add_label_ids and remove_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_merge_requests, issue_no_labels] }
      let(:add_labels) { [bug] }
      let(:remove_labels) { [merge_requests] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(bug.id))
      end

      it 'removes the label IDs from all issues passed' do
        expect(issues.map(&:reload).flat_map(&:label_ids)).not_to include(merge_requests.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end

    context 'when add_label_ids and label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_regression, issue_bug_and_merge_requests] }
      let(:labels) { [merge_requests] }
      let(:add_labels) { [regression] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(regression.id))
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(bug.id))
      end

      it 'does not update issues not passed in' do
        expect(issue_no_labels.label_ids).to be_empty
      end
    end

    context 'when remove_label_ids and label_ids are passed' do
      let(:issues) { [issue_no_labels, issue_bug_and_regression] }
      let(:labels) { [merge_requests] }
      let(:remove_labels) { [regression] }

      it 'removes the label IDs from all issues passed' do
        expect(issues.map(&:reload).flat_map(&:label_ids)).not_to include(regression.id)
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).flat_map(&:label_ids)).not_to include(merge_requests.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_all_labels.label_ids).to contain_exactly(bug.id, regression.id, merge_requests.id)
      end
    end

    context 'when add_label_ids, remove_label_ids, and label_ids are passed' do
      let(:issues) { [issue_bug_and_merge_requests, issue_no_labels] }
      let(:labels) { [regression] }
      let(:add_labels) { [bug] }
      let(:remove_labels) { [merge_requests] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(bug.id))
      end

      it 'removes the label IDs from all issues passed' do
        expect(issues.map(&:reload).flat_map(&:label_ids)).not_to include(merge_requests.id)
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).flat_map(&:label_ids)).not_to include(regression.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end
  end

  context 'with issuables at a project level' do
    let(:parent) { project }

    describe 'close issues' do
      let(:issues) { create_list(:issue, 2, project: project) }

      it 'succeeds and returns the correct number of issues updated' do
        result = bulk_update(issues, state_event: 'close')

        expect(result[:success]).to be_truthy
        expect(result[:count]).to eq(issues.count)
      end

      it 'closes all the issues passed' do
        bulk_update(issues, state_event: 'close')

        expect(project.issues.opened).to be_empty
        expect(project.issues.closed).not_to be_empty
      end
    end

    describe 'reopen issues' do
      let(:issues) { create_list(:closed_issue, 2, project: project) }

      it 'succeeds and returns the correct number of issues updated' do
        result = bulk_update(issues, state_event: 'reopen')

        expect(result[:success]).to be_truthy
        expect(result[:count]).to eq(issues.count)
      end

      it 'reopens all the issues passed' do
        bulk_update(issues, state_event: 'reopen')

        expect(project.issues.closed).to be_empty
        expect(project.issues.opened).not_to be_empty
      end
    end

    describe 'updating merge request assignee' do
      let(:merge_request) { create(:merge_request, target_project: project, source_project: project, assignees: [user]) }

      context 'when the new assignee ID is a valid user' do
        it 'succeeds' do
          new_assignee = create(:user)
          project.add_developer(new_assignee)

          result = bulk_update(merge_request, assignee_ids: [user.id, new_assignee.id])

          expect(result[:success]).to be_truthy
          expect(result[:count]).to eq(1)
        end

        it 'updates the assignee to the user ID passed' do
          assignee = create(:user)
          project.add_developer(assignee)

          expect { bulk_update(merge_request, assignee_ids: [assignee.id]) }
            .to change { merge_request.reload.assignee_ids }.from([user.id]).to([assignee.id])
        end
      end

      context "when the new assignee ID is #{IssuableFinder::NONE}" do
        it 'unassigns the issues' do
          expect { bulk_update(merge_request, assignee_ids: [IssuableFinder::NONE]) }
            .to change { merge_request.reload.assignee_ids }.to([])
        end
      end

      context 'when the new assignee ID is not present' do
        it 'does not unassign' do
          expect { bulk_update(merge_request, assignee_ids: []) }
            .not_to change { merge_request.reload.assignee_ids }
        end
      end
    end

    describe 'updating issue assignee' do
      let(:issue) { create(:issue, project: project, assignees: [user]) }

      context 'when the new assignee ID is a valid user' do
        it 'succeeds' do
          new_assignee = create(:user)
          project.add_developer(new_assignee)

          result = bulk_update(issue, assignee_ids: [new_assignee.id])

          expect(result[:success]).to be_truthy
          expect(result[:count]).to eq(1)
        end

        it 'updates the assignee to the user ID passed' do
          assignee = create(:user)
          project.add_developer(assignee)
          expect { bulk_update(issue, assignee_ids: [assignee.id]) }
            .to change { issue.reload.assignees.first }.from(user).to(assignee)
        end
      end

      context "when the new assignee ID is #{IssuableFinder::NONE}" do
        it "unassigns the issues" do
          expect { bulk_update(issue, assignee_ids: [IssuableFinder::NONE.to_s]) }
            .to change { issue.reload.assignees.count }.from(1).to(0)
        end
      end

      context 'when the new assignee ID is not present' do
        it 'does not unassign' do
          expect { bulk_update(issue, assignee_ids: []) }
            .not_to change(issue.assignees, :count)
        end
      end
    end

    describe 'updating milestones' do
      let(:issuables) { [create(:issue, project: project)] }
      let(:milestone) { create(:milestone, project: project) }

      it_behaves_like 'updates milestones'
    end

    describe 'updating labels' do
      let(:bug) { create(:label, project: project) }
      let(:regression) { create(:label, project: project) }
      let(:merge_requests) { create(:label, project: project) }

      it_behaves_like 'updating labels'
    end

    describe 'subscribe to issues' do
      let(:issues) { create_list(:issue, 2, project: project) }

      it 'subscribes the given user' do
        bulk_update(issues, subscription_event: 'subscribe')

        expect(issues).to all(be_subscribed(user, project))
      end
    end

    describe 'unsubscribe from issues' do
      let(:issues) do
        create_list(:closed_issue, 2, project: project) do |issue|
          issue.subscriptions.create(user: user, project: project, subscribed: true)
        end
      end

      it 'unsubscribes the given user' do
        bulk_update(issues, subscription_event: 'unsubscribe')

        issues.each do |issue|
          expect(issue).not_to be_subscribed(user, project)
        end
      end
    end

    describe 'updating issues from external project' do
      it 'updates only issues that belong to the parent project' do
        issue1 = create(:issue, project: project)
        issue2 = create(:issue, project: create(:project))
        result = bulk_update([issue1, issue2], assignee_ids: [user.id])

        expect(result[:success]).to be_truthy
        expect(result[:count]).to eq(1)

        expect(issue1.reload.assignees).to eq([user])
        expect(issue2.reload.assignees).to be_empty
      end
    end
  end

  context 'with issuables at a group level' do
    let(:group) { create(:group) }
    let(:parent) { group }

    before do
      group.add_reporter(user)
    end

    describe 'updating milestones' do
      let(:milestone) { create(:milestone, group: group) }
      let(:project)   { create(:project, :repository, group: group) }

      before do
        group.add_maintainer(user)
      end

      context 'when issues' do
        let(:issue1)    { create(:issue, project: project) }
        let(:issue2)    { create(:issue, project: project) }
        let(:issuables) { [issue1, issue2] }

        it_behaves_like 'updates milestones'
      end

      context 'when merge requests' do
        let(:merge_request1) { create(:merge_request, source_project: project, source_branch: 'branch-1') }
        let(:merge_request2) { create(:merge_request, source_project: project, source_branch: 'branch-2') }
        let(:issuables)      { [merge_request1, merge_request2] }

        it_behaves_like 'updates milestones'
      end
    end

    describe 'updating labels' do
      let(:project)        { create(:project, :repository, group: group) }
      let(:bug)            { create(:group_label, group: group) }
      let(:regression)     { create(:group_label, group: group) }
      let(:merge_requests) { create(:group_label, group: group) }

      it_behaves_like 'updating labels'
    end

    describe 'with issues from external group' do
      it 'updates issues that belong to the parent group or descendants' do
        issue1 = create(:issue, project: create(:project, group: group))
        issue2 = create(:issue, project: create(:project, group: create(:group)))
        issue3 = create(:issue, project: create(:project, group: create(:group, parent: group)))
        milestone = create(:milestone, group: group)
        result = bulk_update([issue1, issue2, issue3], milestone_id: milestone.id)

        expect(result[:success]).to be_truthy
        expect(result[:count]).to eq(2)

        expect(issue1.reload.milestone).to eq(milestone)
        expect(issue2.reload.milestone).to be_nil
        expect(issue3.reload.milestone).to eq(milestone)
      end
    end
  end
end
