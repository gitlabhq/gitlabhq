require 'spec_helper'
describe "Dashboard" do
  before do 
    @project = Factory :project
    @user = User.create(:email => "test917@mail.com",
                        :name => "John Smith",
                        :password => "123456",
                        :password_confirmation => "123456")
    @project.add_access(@user, :read, :write)
    login_with(@user)
  end

  describe "GET /dashboard" do
    before do
      visit dashboard_path
    end

    it "should be on dashboard page" do
      current_path.should == dashboard_path
    end

    it "should have projects panel" do
      page.should have_content(@project.name)
    end
  end

  describe "GET /dashboard/activities" do
    before do
      visit dashboard_activities_path
    end

    it "should be on dashboard page" do
      current_path.should == dashboard_activities_path
    end

    it "should have projects panel" do
      page.should have_content(@project.name)
    end
  end
end
