require 'spec_helper'

describe "Dashboard" do
  before { login_as :user }

  describe "GET /dashboard" do
    before do
      @project = Factory :project
      @project.add_access(@user, :read, :write)
      visit dashboard_path
    end

    it "should be on dashboard page" do
      current_path.should == dashboard_path
    end

    it "should have projects panel" do
      within ".project-list"  do
        page.should have_content(@project.name)
      end
    end

    it "should have news feed" do
      within "#news-feed"  do
        page.should have_content("master")
        page.should have_content(@project.commit.author.name)
        page.should have_content(@project.commit.safe_message)
      end
    end
  end
end
