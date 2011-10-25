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
      click_link "Add new"
    end

    it "should open new team member popup" do 
      page.should have_content("Add new member to project")
    end

    describe "fill in" do 
      before do
        click_link "Select user"
        click_link @user_1.name

        within "#team_member_new" do 
          check "team_member_read"
          check "team_member_write"
        end
      end

      it { expect { click_button "Save";sleep(1) }.to change {UsersProject.count}.by(1) }

      it "should add new member to table" do 
        click_button "Save"
        @member = UsersProject.last

        page.should have_content @user_1.name

        @member.read.should be_true
        @member.write.should be_true
        @member.admin.should be_false
      end

      it "should not allow creation without access selected" do 
        within "#team_member_new" do 
          uncheck "team_member_read"
          uncheck "team_member_write"
          uncheck "team_member_admin"
        end

        expect { click_button "Save" }.to_not change {UsersProject.count}
        page.should have_content("Please choose at least one Role in the Access list")
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
