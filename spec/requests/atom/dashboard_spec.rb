require 'spec_helper'

describe "User Dashboard" do
  before { login_as :user }

  describe "GET /" do
    before do
      @project = Factory :project, owner: @user
      @project.add_access(@user, :read)
      visit dashboard_path
    end

    it "should render projects atom feed via private token" do
      logout

      visit dashboard_path(:atom, private_token: @user.private_token)
      page.body.should have_selector("feed title")
    end

    it "should not render projects page via private token" do
      logout

      visit dashboard_path(private_token: @user.private_token)
      current_path.should == new_user_session_path
    end
  end
end
