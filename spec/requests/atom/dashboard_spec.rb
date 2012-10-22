require 'spec_helper'

describe "Dashboard Feed" do
  describe "GET /" do
    let!(:user) { Factory :user }

    context "projects atom feed via private token" do
      it "should render projects atom feed" do
        visit dashboard_path(:atom, private_token: user.private_token)
        page.body.should have_selector("feed title")
      end
    end
  end
end
