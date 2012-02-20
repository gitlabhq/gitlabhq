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

    it "should have link to last commit for activities tab" do
      page.should have_content(@project.commit.safe_message[0..20])
    end
  end

  describe "GET /:project_name/repository/branches" do
    before do
      visit branches_project_repository_path(@project)
    end

    it "should have link to repo activities" do
      page.should have_content("Branches")
      page.should have_content("master")
    end
  end

  # TODO: Add new repo to seeds with tags list
  describe "GET /:project_name/repository/tags" do
    before do
      visit tags_project_repository_path(@project)
    end

    it "should have link to repo activities" do
      page.should have_content("Tags")
      page.should have_content("No tags")
    end
  end
end

