require 'spec_helper'

describe "TeamMembers" do
  before do 
    login_as :user
    @project = Factory :project
    @project.add_access(@user, :read, :admin)
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
        check "team_member_read"
        click_link "Select user"
        click_link @user_1.name
        #select @user_1.name, :from => "team_member_user_id"
      end

      it { expect { click_button "Save" }.to change {UsersProject.count}.by(1) }

      it "should add new member to table" do 
        click_button "Save"

        page.should_not have_content("Add new member")
        page.should have_content @user_1.name
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
