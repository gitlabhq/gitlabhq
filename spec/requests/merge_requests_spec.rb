require 'spec_helper'

describe "MergeRequests" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :read, :write)
    @merge_request = Factory :merge_request,
      :author => @user,
      :assignee => @user,
      :project => project
  end

  describe "GET /merge_requests" do
    before do 
      visit project_merge_requests_path(project)
    end

    subject { page }

    it { should have_content(@merge_request.title[0..10]) }
    it { should have_content(@merge_request.target_branch) }
    it { should have_content(@merge_request.source_branch) }
    it { should have_content(@merge_request.assignee.name) }
  end

  describe "GET /merge_request/:id" do 
    before do 
      visit project_merge_request_path(project, @merge_request)
    end

    subject { page }

    it { should have_content(@merge_request.title[0..10]) }
    it { should have_content(@merge_request.target_branch) }
    it { should have_content(@merge_request.source_branch) }
    it { should have_content(@merge_request.assignee.name) }

    describe "Close merge request" do 
      before { click_link "Close" }

      it { should have_content(@merge_request.title[0..10]) }
      it "Show page should inform user that merge request closed" do 
        page.should have_content "Reopen" 
      end
    end
  end

  describe "GET /merge_requests/new" do 
    before do
      visit new_project_merge_request_path(project)
      fill_in "merge_request_title", :with => "Merge Request Title" 
      select "master", :from => "merge_request_source_branch"
      select "master", :from => "merge_request_target_branch"
      select @user.name, :from => "merge_request_assignee_id"
      click_button "Save"
    end

    it { current_path.should == project_merge_request_path(project, project.merge_requests.last) }

    it "should create merge request" do
      page.should have_content "Close"
      page.should have_content @user.name
    end
  end
end
