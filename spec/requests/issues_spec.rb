require 'spec_helper'

describe "Issues" do
  let(:project) { Factory :project }

  before do
    login_as :user
    @user2 = Factory :user

    project.add_access(@user, :read, :write)
    project.add_access(@user2, :read, :write)
  end

  describe "GET /issues" do
    before do
      @issue = Factory :issue,
        :author => @user,
        :assignee => @user,
        :project => project

      visit project_issues_path(project)
    end

    subject { page }

    it { should have_content(@issue.title[0..20]) }
    it { should have_content(@issue.project.name) }
    it { should have_content(@issue.assignee.name) }

    it "should render atom feed" do
      visit project_issues_path(project, :atom)

      page.response_headers['Content-Type'].should have_content("application/atom+xml")
      page.body.should have_selector("title", :text => "#{project.name} issues")
      page.body.should have_selector("author email", :text => @issue.author_email)
      page.body.should have_selector("entry summary", :text => @issue.title)
    end

    it "should render atom feed via private token" do
      logout
      visit project_issues_path(project, :atom, :private_token => @user.private_token)

      page.response_headers['Content-Type'].should have_content("application/atom+xml")
      page.body.should have_selector("title", :text => "#{project.name} issues")
      page.body.should have_selector("author email", :text => @issue.author_email)
      page.body.should have_selector("entry summary", :text => @issue.title)
    end

    describe "Destroy" do
      before do
        # admin access to remove issue
        @user.users_projects.destroy_all
        project.add_access(@user, :read, :write, :admin)
        visit edit_project_issue_path(project, @issue)
      end

      it "should remove entry" do
        expect {
          click_link "Remove"
        }.to change { Issue.count }.by(-1)
      end
    end

    describe "statuses" do
      before do
        @closed_issue = Factory :issue,
          :author => @user,
          :assignee => @user,
          :project => project,
          :closed => true
      end

      it "should show only open" do
        should have_content(@issue.title[0..25])
        should have_no_content(@closed_issue.title)
      end

      it "should show only closed" do
        click_link "Closed"
        should have_no_content(@issue.title)
        should have_content(@closed_issue.title[0..25])
      end

      it "should show all" do
        click_link "All"
        should have_content(@issue.title[0..25])
        should have_content(@closed_issue.title[0..25])
      end
    end
  end

  describe "New issue", :js => true do
    before do
      visit project_issues_path(project)
      click_link "New Issue"
    end

    it "should open new issue form" do
      page.should have_content("New Issue")
    end

    describe "fill in" do
      describe 'assign to me' do
        before do
          fill_in "issue_title", :with => "bug 345"
          page.execute_script("$('#issue_assignee_id').show();")
          select @user.name, :from => "issue_assignee_id" 
        end

        it { expect { click_button "Save" }.to change {Issue.count}.by(1) }

        it "should add new issue to table" do
          click_button "Save"

          page.should_not have_content("Add new issue")
          page.should have_content @user.name
          page.should have_content "bug 345"
          page.should have_content project.name
        end

        it "should call send mail" do
          Notify.should_not_receive(:new_issue_email)
          click_button "Save"
        end
      end

      describe 'assign to other' do
        before do
          fill_in "issue_title", :with => "bug 345"
          page.execute_script("$('#issue_assignee_id').show();")
          select @user2.name, :from => "issue_assignee_id" 
        end

        it { expect { click_button "Save" }.to change {Issue.count}.by(1) }

        it "should add new issue to table" do
          click_button "Save"

          page.should_not have_content("Add new issue")
          page.should have_content @user2.name
          page.should have_content "bug 345"
          page.should have_content project.name
        end

        it "should call send mail" do
          Notify.should_receive(:new_issue_email).and_return(stub(:deliver => true))
          click_button "Save"
        end

        it "should send valid email to user" do
          click_button "Save"
          issue = Issue.last
          email = ActionMailer::Base.deliveries.last
          email.subject.should have_content("New Issue was created")
          email.body.should have_content(issue.title)
        end

      end
    end
  end

  describe "Show issue" do
    before do
      @issue = Factory :issue,
        :author => @user,
        :assignee => @user,
        :project => project

      visit project_issue_path(project, @issue)
    end

    it "should have valid show page for issue" do
      page.should have_content @issue.title
      page.should have_content @user.name
    end
  end

  describe "Edit issue", :js => true do
    before do
      @issue = Factory :issue,
        :author => @user,
        :assignee => @user,
        :project => project
      visit project_issues_path(project)
      click_link "Edit"
    end

    it "should open new issue popup" do
      page.should have_content("Issue ##{@issue.id}")
    end

    describe "fill in" do
      before do
        fill_in "issue_title", :with => "bug 345"
      end

      it { expect { click_button "Save" }.to_not change {Issue.count} }

      it "should update issue fields" do
        click_button "Save"

        page.should have_content @user.name
        page.should have_content "bug 345"
        page.should have_content project.name
      end
    end
  end

  describe "Search issue", :js => true do
    before do
      ['foobar', 'foobar2', 'gitlab'].each do |title|
        @issue = Factory :issue,
          :author   => @user,
          :assignee => @user,
          :project  => project,
          :title    => title
        @issue.save
      end
    end

    it "should be able to search on different statuses" do
      @issue = Issue.first
      @issue.closed = true
      @issue.save

      visit project_issues_path(project)
      click_link 'Closed'
      fill_in 'issue_search', :with => 'foobar'

      page.should have_content 'foobar'
      page.should_not have_content 'foobar2'
      page.should_not have_content 'gitlab'
    end

    it "should search for term and return the correct results" do
      visit project_issues_path(project)
      fill_in 'issue_search', :with => 'foobar'

      page.should have_content 'foobar'
      page.should have_content 'foobar2'
      page.should_not have_content 'gitlab'
    end

    it "should return all results if term has been cleared" do
      visit project_issues_path(project)
      fill_in "issue_search", :with => "foobar"
      # Because fill_in, :with => "" triggers nothing we need to trigger a keyup event
      page.execute_script("$('.issue_search').val('').keyup();");

      page.should have_content 'foobar'
      page.should have_content 'foobar2'
      page.should have_content 'gitlab'
    end
  end
end
