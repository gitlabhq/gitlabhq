require 'spec_helper'

describe Issues::BulkUpdateService do
  let(:issue) {
    create(:issue, project: @project)
  }

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
        update: {
          status: 'closed',
          issues_ids: @issues.map(&:id)
        }
      }
    end

    it {
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      result[:success].should be_true
      result[:count].should == @issues.count

      @project.issues.opened.should be_empty
      @project.issues.closed.should_not be_empty
    }

  end

  describe :reopen_issues do

    before do
      @issues = 5.times.collect do
        create(:closed_issue, project: @project)
      end
      @params = {
        update: {
          status: 'reopen',
          issues_ids: @issues.map(&:id)
        }
      }
    end

    it {
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      result[:success].should be_true
      result[:count].should == @issues.count

      @project.issues.closed.should be_empty
      @project.issues.opened.should_not be_empty
    }

  end

  describe :update_assignee do

    before do
      @new_assignee = create :user
      @params = {
        update: {
          issues_ids: [issue.id],
          assignee_id: @new_assignee.id
        }
      }
    end

    it {
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      result[:success].should be_true
      result[:count].should == 1

      @project.issues.first.assignee.should == @new_assignee
    }

  end

  describe :update_milestone do

    before do
      @milestone = create :milestone
      @params = {
        update: {
          issues_ids: [issue.id],
          milestone_id: @milestone.id
        }
      }
    end

    it {
      result = Issues::BulkUpdateService.new(@project, @user, @params).execute
      result[:success].should be_true
      result[:count].should == 1

      @project.issues.first.milestone.should == @milestone
    }
  end

end
