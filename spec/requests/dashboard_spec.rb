require 'spec_helper'
__END__
# Disabled for now
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
      within ".project-list"  do
        page.should have_content(@project.name)
      end
    end

    # Temporary disabled cause of travis
    # TODO: fix or rewrite
    #it "should have news feed" do
      #within "#news-feed"  do
        #page.should have_content("commit")
        #page.should have_content(@project.commit.author.name)
        #page.should have_content(@project.commit.safe_message)
      #end
    #end
  end
end
