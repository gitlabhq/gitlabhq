require 'spec_helper'

describe "Repository" do

  before do
    @user = Factory :user
    @project = Factory :project
    @project.add_access(@user, :read, :write)
    login_with @user
  end

  describe "GET /:project_name/repository" do
    before do
      visit project_repository_path(@project)
    end

    it "should be on projects page" do
      current_path.should == project_repository_path(@project)
    end

    it "should have link to repo activities" do
      page.should have_content("Activities")
    end

    it "should have link to last commit for activities tab" do
      page.should have_content(@project.commit.safe_message[0..20])
      page.should have_content(@project.commit.author_name)
    end

    it "should show commits list" do
      page.all(:css, ".project-update").size.should == 20
    end
  end
end

