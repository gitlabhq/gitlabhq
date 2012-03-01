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
      click_link(@user.name)
      page.should have_content @user.skype
      page.should_not have_content 'Twitter'
    end
  end

  describe "New Team member" do
    before do
      @user_1 = Factory :user
      visit team_project_path(@project)
      click_link "New Team Member"
    end

    it "should open new team member popup" do
      page.should have_content("New Team member")
    end

    describe "fill in" do
      before do
        within "#new_team_member" do 
          select @user_1.name, :from => "team_member_user_id"
          select "Reporter", :from => "team_member_project_access"
        end
      end

      it { expect { click_button "Save";sleep(1) }.to change {UsersProject.count}.by(1) }

      it "should add new member to table" do
        click_button "Save"
        @member = UsersProject.last

        page.should have_content @user_1.name

        @member.reload
        @member.project_access.should == UsersProject::REPORTER
      end
    end
  end

  describe "Cancel membership" do
    it "should cancel membership" do
      visit project_team_member_path(@project, @project.users_projects.last)
      expect { click_link "Remove from team" }.to change { UsersProject.count }.by(-1)
    end
  end
end
