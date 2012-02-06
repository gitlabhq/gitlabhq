require 'spec_helper'

describe "Commits" do
  let(:project) { Factory :project }
  let!(:commit) { project.commit }
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
      page.should have_content(commit.message)
      page.should have_content(commit.id.to_s[0..5])
    end

    it "should render atom feed" do
      visit project_commits_path(project, :atom)

      page.response_headers['Content-Type'].should have_content("application/atom+xml")
      page.body.should have_selector("title", :text => "Recent commits to #{project.name}")
      page.body.should have_selector("author email", :text => commit.author_email)
      page.body.should have_selector("entry summary", :text => commit.message)
    end

    it "should render atom feed via private token" do
      logout
      visit project_commits_path(project, :atom, :private_token => @user.private_token)

      page.response_headers['Content-Type'].should have_content("application/atom+xml")
      page.body.should have_selector("title", :text => "Recent commits to #{project.name}")
      page.body.should have_selector("author email", :text => commit.author_email)
      page.body.should have_selector("entry summary", :text => commit.message)
    end
  end

  describe "GET /commits/:id" do
    before do
      visit project_commit_path(project, commit.id)
    end

    it "should have valid path" do
      current_path.should == project_commit_path(project, commit.id)
    end
  end

  describe "GET /commits/compare" do 
    before do
      visit compare_project_commits_path(project)
    end

    it "should have valid path" do
      current_path.should == compare_project_commits_path(project)
    end
  end
end
