require 'spec_helper'

describe "TeamMembers" do
  before do
    login_as :user
    @project = Factory :project
    @project.add_access(@user, :read, :admin)
  end

  describe "View profile" do
    it "should be available" do
      visit(team_project_path(@project))
      within "#team-table" do
        click_link(@user.name)
      end
      page.should have_content @user.skype
      page.should_not have_content 'Twitter'
    end
  end

  describe "New Team member", :js => true do
    before do
      @user_1 = Factory :user
      visit team_project_path(@project)
      click_link "New Team Member"
    end

    it "should open new team member popup" do
      page.should have_content("Add new member to project")
    end

    describe "fill in" do
      before do
        page.execute_script("$('#team_member_user_id').show();")
        within "#team_member_new" do 
          select @user_1.name, :from => "team_member_user_id"
          select "Report", :from => "team_member_project_access"
          select "Pull",   :from => "team_member_repo_access"
        end
      end

      it { expect { click_button "Save";sleep(1) }.to change {UsersProject.count}.by(1) }

      it "should add new member to table" do
        click_button "Save"
        @member = UsersProject.last

        page.should have_content @user_1.name

        @member.reload
        @member.project_access.should == Project::PROJECT_RW
        @member.repo_access.should == Repository::REPO_R
      end
    end
  end

  describe "Cancel membership" do
    it "should cancel membership" do
      visit team_project_path(@project)
      expect { click_link "Cancel" }.to change { UsersProject.count }.by(-1)
    end
  end
end
