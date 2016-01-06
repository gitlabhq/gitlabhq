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
      @issues = 5.times.collect do
        create(:issue, project: @project)
      end
      @params = {
        state_event: 'close',
        issues_ids: @issues.map(&:id)
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
      @issues = 5.times.collect do
        create(:closed_issue, project: @project)
      end
      @params = {
        state_event: 'reopen',
        issues_ids: @issues.map(&:id)
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
        issues_ids: [issue.id],
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
      @milestone = create :milestone
      @params = {
        issues_ids: [issue.id],
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

end
