require 'spec_helper'

describe "User Issues Dashboard" do
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

      @issue1 = Factory :issue,
        :author => @user,
        :assignee => @user,
        :project => @project1

      @issue2 = Factory :issue,
        :author => @user,
        :assignee => @user,
        :project => @project2

      visit dashboard_issues_path
    end

    subject { page }

    it { should have_content(@issue1.title[0..10]) }
    it { should have_content(@issue1.project.name) }

    it { should have_content(@issue2.title[0..10]) }
    it { should have_content(@issue2.project.name) }

    describe "atom feed", :js => false do
      it "should render atom feed via private token" do
        logout
        visit dashboard_issues_path(:atom, :private_token => @user.private_token)

        page.response_headers['Content-Type'].should have_content("application/atom+xml")
        page.body.should have_selector("title", :text => "#{@user.name} issues")
        page.body.should have_selector("author email", :text => @issue1.author_email)
        page.body.should have_selector("entry summary", :text => @issue1.title)
        page.body.should have_selector("author email", :text => @issue2.author_email)
        page.body.should have_selector("entry summary", :text => @issue2.title)
      end
    end
  end
end
