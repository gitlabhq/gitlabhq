require 'spec_helper'

describe Issues::BulkUpdateService, services: true do
  let(:user) { create(:user) }
  let(:project) { Projects::CreateService.new(user, namespace: user.namespace, name: 'test').execute }

  let!(:result) { Issues::BulkUpdateService.new(project, user, params).execute }

  describe :close_issue do
    let(:issues) { create_list(:issue, 5, project: project) }
    let(:params) do
      {
        state_event: 'close',
        issues_ids: issues.map(&:id).join(',')
      }
    end

    it 'succeeds and returns the correct number of issues updated' do
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(issues.count)
    end

    it 'closes all the issues passed' do
      expect(project.issues.opened).to be_empty
      expect(project.issues.closed).not_to be_empty
    end
  end

  describe :reopen_issues do
    let(:issues) { create_list(:closed_issue, 5, project: project) }
    let(:params) do
      {
        state_event: 'reopen',
        issues_ids: issues.map(&:id).join(',')
      }
    end

    it 'succeeds and returns the correct number of issues updated' do
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(issues.count)
    end

    it 'reopens all the issues passed' do
      expect(project.issues.closed).to be_empty
      expect(project.issues.opened).not_to be_empty
    end
  end

  describe 'updating assignee' do
    let(:issue) do
      create(:issue, project: project) { |issue| issue.update_attributes(assignee: user) }
    end

    let(:params) do
      {
        assignee_id: assignee_id,
        issues_ids: issue.id.to_s
      }
    end

    context 'when the new assignee ID is a valid user' do
      let(:new_assignee) { create(:user) }
      let(:assignee_id) { new_assignee.id }

      it 'succeeds' do
        expect(result[:success]).to be_truthy
        expect(result[:count]).to eq(1)
      end

      it 'updates the assignee to the use ID passed' do
        expect(issue.reload.assignee).to eq(new_assignee)
      end
    end

    context 'when the new assignee ID is -1' do
      let(:assignee_id) { -1 }

      it 'unassigns the issues' do
        expect(issue.reload.assignee).to be_nil
      end
    end

    context 'when the new assignee ID is not present' do
      let(:assignee_id) { nil }

      it 'does not unassign' do
        expect(issue.reload.assignee).to eq(user)
      end
    end
  end

  describe 'updating milestones' do
    let(:issue) { create(:issue, project: project) }
    let(:milestone) { create(:milestone, project: project) }

    let(:params) do
      {
        issues_ids: issue.id.to_s,
        milestone_id: milestone.id
      }
    end

    it 'succeeds' do
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(1)
    end

    it 'updates the issue milestone' do
      expect(project.issues.first.milestone).to eq(milestone)
    end
  end

  describe 'updating labels' do
    def create_issue_with_labels(labels)
      create(:issue, project: project) { |issue| issue.update_attributes(labels: labels) }
    end

    let(:bug) { create(:label, project: project) }
    let(:regression) { create(:label, project: project) }
    let(:merge_requests) { create(:label, project: project) }

    let(:issue_all_labels) { create_issue_with_labels([bug, regression, merge_requests]) }
    let(:issue_bug_and_regression) { create_issue_with_labels([bug, regression]) }
    let(:issue_bug_and_merge_requests) { create_issue_with_labels([bug, merge_requests]) }
    let(:issue_no_labels) { create(:issue, project: project) }
    let(:issues) { [issue_all_labels, issue_bug_and_regression, issue_bug_and_merge_requests, issue_no_labels] }

    let(:labels) { [] }
    let(:add_labels) { [] }
    let(:remove_labels) { [] }

    let(:params) do
      {
        label_ids: labels.map(&:id),
        add_label_ids: add_labels.map(&:id),
        remove_label_ids: remove_labels.map(&:id),
        issues_ids: issues.map(&:id).join(',')
      }
    end

    context 'when label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_no_labels] }
      let(:labels) { [bug, regression] }

      it 'updates the labels of all issues passed to the labels passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(eq(labels.map(&:id)))
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
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(merge_requests.id)
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

      it 'remove the label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(regression.id)
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(merge_requests.id)
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
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(merge_requests.id)
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(regression.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end
  end

  describe :subscribe_issues do
    let(:issues) { create_list(:issue, 5, project: project) }
    let(:params) do
      {
        subscription_event: 'subscribe',
        issues_ids: issues.map(&:id).join(',')
      }
    end

    it 'subscribes the given user' do
      issues.each do |issue|
        expect(issue.subscribed?(user)).to be_truthy
      end
    end
  end

  describe :unsubscribe_issues do
    let(:issues) { create_list(:closed_issue, 5, project: project) }
    let(:params) do
      {
        subscription_event: 'unsubscribe',
        issues_ids: issues.map(&:id).join(',')
      }
    end

    before do
      issues.each do |issue|
        issue.subscriptions.create(user: user, subscribed: true)
      end
    end

    it 'unsubscribes the given user' do
      issues.each do |issue|
        expect(issue.subscribed?(user)).to be_falsey
      end
    end
  end
end
