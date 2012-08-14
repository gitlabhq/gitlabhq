require 'spec_helper'

describe "Issues" do
  let(:project) { Factory :project }

  before do
    login_as :user
    @user2 = Factory :user

    project.add_access(@user, :read, :write)
    project.add_access(@user2, :read, :write)
  end

  describe "Edit issue", js: true do
    before do
      @issue = Factory :issue,
        author: @user,
        assignee: @user,
        project: project
      visit project_issues_path(project)
      click_link "Edit"
    end

    it "should open new issue popup" do
      page.should have_content("Issue ##{@issue.id}")
    end

    describe "fill in" do
      before do
        fill_in "issue_title", with: "bug 345"
        fill_in "issue_description", with: "bug description"
      end

      it { expect { click_button "Save changes" }.to_not change {Issue.count} }

      it "should update issue fields" do
        click_button "Save changes"

        page.should have_content @user.name
        page.should have_content "bug 345"
        page.should have_content project.name
      end
    end
  end

  describe "Search issue", js: true do
    before do
      ['foobar', 'foobar2', 'gitlab'].each do |title|
        @issue = Factory :issue,
          author: @user,
          assignee: @user,
          project: project,
          title: title
        @issue.save
      end
    end

    it "should be able to search on different statuses" do
      @issue = Issue.first
      @issue.closed = true
      @issue.save

      visit project_issues_path(project)
      click_link 'Closed'
      fill_in 'issue_search', with: 'foobar'

      page.should have_content 'foobar'
      page.should_not have_content 'foobar2'
      page.should_not have_content 'gitlab'
    end

    it "should search for term and return the correct results" do
      visit project_issues_path(project)
      fill_in 'issue_search', with: 'foobar'

      page.should have_content 'foobar'
      page.should have_content 'foobar2'
      page.should_not have_content 'gitlab'
    end

    it "should return all results if term has been cleared" do
      visit project_issues_path(project)
      fill_in "issue_search", with: "foobar"
      # Because fill_in, with: "" triggers nothing we need to trigger a keyup event
      page.execute_script("$('.issue_search').val('').keyup();");

      page.should have_content 'foobar'
      page.should have_content 'foobar2'
      page.should have_content 'gitlab'
    end
  end

  describe "Filter issue" do
    before do
      ['foobar', 'barbaz', 'gitlab'].each do |title|
        @issue = Factory :issue,
          author: @user,
          assignee: @user,
          project: project,
          title: title
      end

      @issue = Issue.first
      @issue.milestone = Factory(:milestone, project: project)
      @issue.assignee = nil
      @issue.save
    end

    it "should allow filtering by issues with no specified milestone" do
      visit project_issues_path(project, milestone_id: '0')

      page.should_not have_content 'foobar'
      page.should have_content 'barbaz'
      page.should have_content 'gitlab'
    end

    it "should allow filtering by a specified milestone" do
      visit project_issues_path(project, milestone_id: @issue.milestone.id)

      page.should have_content 'foobar'
      page.should_not have_content 'barbaz'
      page.should_not have_content 'gitlab'
    end

    it "should allow filtering by issues with no specified assignee" do
      visit project_issues_path(project, assignee_id: '0')

      page.should have_content 'foobar'
      page.should_not have_content 'barbaz'
      page.should_not have_content 'gitlab'
    end

    it "should allow filtering by a specified assignee" do
      visit project_issues_path(project, assignee_id: @user.id)

      page.should_not have_content 'foobar'
      page.should have_content 'barbaz'
      page.should have_content 'gitlab'
    end
  end
end
