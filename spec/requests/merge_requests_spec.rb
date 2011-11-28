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

    it { should have_content(@merge_request.title) }
    it { should have_content(@merge_request.target_branch) }
    it { should have_content(@merge_request.source_branch) }
    it { should have_content(@merge_request.assignee.name) }
  end

  describe "GET /merge_request/:id" do 
    before do 
      visit project_merge_request_path(project, @merge_request)
    end

    subject { page }

    it { should have_content(@merge_request.title) }
    it { should have_content(@merge_request.target_branch) }
    it { should have_content(@merge_request.source_branch) }
    it { should have_content(@merge_request.assignee.name) }

    describe "Close merge request" do 
      before { click_link "Close" }

      it { should have_content(@merge_request.title) }
      it "Show page should inform user that merge request closed" do 
        within ".merge-request-show-holder h3" do 
          page.should have_content "Closed" 
        end
      end
    end
  end
end
