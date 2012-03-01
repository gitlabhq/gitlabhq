require 'spec_helper'

describe "User MergeRequests" do
  describe "GET /issues" do
    before do

      login_as :user

      @project1 = Factory :project,
        :path => "project1",
        :code => "TEST1"

      @project2 = Factory :project,
        :path => "project2",
        :code => "TEST2"

      @project1.add_access(@user, :read, :write)
      @project2.add_access(@user, :read, :write)

      @merge_request1 = Factory :merge_request,
        :author => @user,
        :assignee => @user,
        :project => @project1

      @merge_request2 = Factory :merge_request,
        :author => @user,
        :assignee => @user,
        :project => @project2

      visit dashboard_merge_requests_path
    end

    subject { page }

    it { should have_content(@merge_request1.title[0..10]) }
    it { should have_content(@merge_request1.project.name) }
    it { should have_content(@merge_request2.title[0..10]) }
    it { should have_content(@merge_request2.project.name) }
  end
end
