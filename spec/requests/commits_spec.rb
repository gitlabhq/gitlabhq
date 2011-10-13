require 'spec_helper'

describe "Commits" do
  let(:project) { Factory :project }
  let!(:commit) { project.repo.commits.first }
  before do 
    login_as :user
    project.add_access(@user, :read)
  end

  describe "GET /commits" do
    before do 
      visit project_commits_path(project)
    end

    it "should have valid path" do
      current_path.should == project_commits_path(project)
    end

    it "should have project name" do 
      page.should have_content(project.name)
    end

    it "should list commits" do 
      page.should have_content(commit.author)
      page.should have_content(commit.message)
    end
  end

  describe "GET /commits/:id" do 
    before do 
      visit project_commit_path(project, commit)
    end

    it "should have valid path" do 
      current_path.should == project_commit_path(project, commit)
    end
  end
end
