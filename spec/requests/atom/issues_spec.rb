require 'spec_helper'

describe "Issues" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :read, :write)
  end

  describe "GET /issues" do
    before do
      @issue = Factory :issue,
        author: @user,
        assignee: @user,
        project: project

      visit project_issues_path(project)
    end

    it "should render atom feed" do
      visit project_issues_path(project, :atom)

      page.response_headers['Content-Type'].should have_content("application/atom+xml")
      page.body.should have_selector("title", text: "#{project.name} issues")
      page.body.should have_selector("author email", text: @issue.author_email)
      page.body.should have_selector("entry summary", text: @issue.title)
    end

    it "should render atom feed via private token" do
      logout
      visit project_issues_path(project, :atom, private_token: @user.private_token)

      page.response_headers['Content-Type'].should have_content("application/atom+xml")
      page.body.should have_selector("title", text: "#{project.name} issues")
      page.body.should have_selector("author email", text: @issue.author_email)
      page.body.should have_selector("entry summary", text: @issue.title)
    end
  end
end
