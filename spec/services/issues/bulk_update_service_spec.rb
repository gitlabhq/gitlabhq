require 'spec_helper'

describe Issues::BulkUpdateService, services: true do
  let(:issue) { create(:issue, project: @project) }

  before do
    @user = create :user
    opts = {
      name: "GitLab",
      namespace: @user.namespace
    }
    @project = Projects::CreateService.new(@user, opts).execute
  end

  describe :close_issue do

    before do
      @issues = create_list(:issue, 5, project: @project)
      @params = {
        state_event: 'close',
        issues_ids: @issues.map(&:id).join(",")
      }
    end

    it do
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(@issues.count)

      expect(@project.issues.opened).to be_empty
      expect(@project.issues.closed).not_to be_empty
    end

  end

  describe :reopen_issues do
    before do
      @issues = create_list(:closed_issue, 5, project: @project)
      @params = {
        state_event: 'reopen',
        issues_ids: @issues.map(&:id).join(",")
      }
    end

    it do
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(@issues.count)

      expect(@project.issues.closed).to be_empty
      expect(@project.issues.opened).not_to be_empty
    end

  end

  describe :update_assignee do

    before do
      @new_assignee = create :user
      @params = {
        issues_ids: issue.id.to_s,
        assignee_id: @new_assignee.id
      }
    end

    it do
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(1)

      expect(@project.issues.first.assignee).to eq(@new_assignee)
    end

    it 'allows mass-unassigning' do
      @project.issues.first.update_attribute(:assignee, @new_assignee)
      expect(@project.issues.first.assignee).not_to be_nil

      @params[:assignee_id] = -1

      Issues::BulkUpdateService.new(@project, @user, @params).execute
      expect(@project.issues.first.assignee).to be_nil
    end

    it 'does not unassign when assignee_id is not present' do
      @project.issues.first.update_attribute(:assignee, @new_assignee)
      expect(@project.issues.first.assignee).not_to be_nil

      @params[:assignee_id] = ''

      Issues::BulkUpdateService.new(@project, @user, @params).execute
      expect(@project.issues.first.assignee).not_to be_nil
    end
  end

  describe :update_milestone do

    before do
      @milestone = create(:milestone, project: @project)
      @params = {
        issues_ids: issue.id.to_s,
        milestone_id: @milestone.id
      }
    end

    it do
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      expect(result[:success]).to be_truthy
      expect(result[:count]).to eq(1)

      expect(@project.issues.first.milestone).to eq(@milestone)
    end
  end

  describe 'updating labels' do
    def create_issue_with_labels(labels)
      create(:issue, project: project) { |issue| issue.labels = labels }
    end

    let(:user) { create(:user) }
    let(:project) { Projects::CreateService.new(user, namespace: user.namespace, name: 'test').execute }
    let(:label_1) { create(:label, project: project) }
    let(:label_2) { create(:label, project: project) }
    let(:label_3) { create(:label, project: project) }

    let(:issue_all_labels) { create_issue_with_labels([label_1, label_2, label_3]) }
    let(:issue_labels_1_and_2) { create_issue_with_labels([label_1, label_2]) }
    let(:issue_labels_1_and_3) { create_issue_with_labels([label_1, label_3]) }
    let(:issue_no_labels) { create(:issue, project: project) }
    let(:issues) { [issue_all_labels, issue_labels_1_and_2, issue_labels_1_and_3, issue_no_labels] }

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

    before { Issues::BulkUpdateService.new(project, user, params).execute }

    context 'when label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_no_labels] }
      let(:labels) { [label_1, label_2] }

      it 'updates the labels of all issues passed to the labels passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(eq(labels.map(&:id)))
      end

      it 'does not update issues not passed in' do
        expect(issue_labels_1_and_2.label_ids).to contain_exactly(label_1.id, label_2.id)
      end
    end

    context 'when add_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_labels_1_and_3, issue_no_labels] }
      let(:add_labels) { [label_1, label_2, label_3] }

      it 'adds those label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(*add_labels.map(&:id)))
      end

      it 'does not update issues not passed in' do
        expect(issue_labels_1_and_2.label_ids).to contain_exactly(label_1.id, label_2.id)
      end
    end

    context 'when remove_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_labels_1_and_3, issue_no_labels] }
      let(:remove_labels) { [label_1, label_2, label_3] }

      it 'removes those label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(be_empty)
      end

      it 'does not update issues not passed in' do
        expect(issue_labels_1_and_2.label_ids).to contain_exactly(label_1.id, label_2.id)
      end
    end

    context 'when add_label_ids and remove_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_labels_1_and_3, issue_no_labels] }
      let(:add_labels) { [label_1] }
      let(:remove_labels) { [label_3] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(label_1.id))
      end

      it 'removes the label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(label_3.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_labels_1_and_2.label_ids).to contain_exactly(label_1.id, label_2.id)
      end
    end

    context 'when add_label_ids and label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_labels_1_and_2, issue_labels_1_and_3] }
      let(:labels) { [label_3] }
      let(:add_labels) { [label_2] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(label_2.id))
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(label_1.id))
      end

      it 'does not update issues not passed in' do
        expect(issue_no_labels.label_ids).to be_empty
      end
    end

    context 'when remove_label_ids and label_ids are passed' do
      let(:issues) { [issue_no_labels, issue_labels_1_and_2] }
      let(:labels) { [label_3] }
      let(:remove_labels) { [label_2] }

      it 'remove the label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(label_2.id)
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(label_3.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_all_labels.label_ids).to contain_exactly(label_1.id, label_2.id, label_3.id)
      end
    end

    context 'when add_label_ids, remove_label_ids, and label_ids are passed' do
      let(:issues) { [issue_labels_1_and_3, issue_no_labels] }
      let(:labels) { [label_2] }
      let(:add_labels) { [label_1] }
      let(:remove_labels) { [label_3] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(label_1.id))
      end

      it 'removes the label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(label_3.id)
      end

      it 'ignores the label IDs parameter' do
        expect(issues.map(&:reload).map(&:label_ids).flatten).not_to include(label_2.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_labels_1_and_2.label_ids).to contain_exactly(label_1.id, label_2.id)
      end
    end
  end
end
