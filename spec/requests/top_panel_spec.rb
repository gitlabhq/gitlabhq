require 'spec_helper'

describe "Top Panel", :js => true do
  before { login_as :user }

  describe "Search autocomplete" do
    before do
      visit projects_path
      fill_in "search", :with => "Ke"
      sleep(2)
      find(:xpath, "//ul[contains(@class,'ui-autocomplete')]/li/a[.=\"Keys\"]").click
    end

    it "should be on projects page" do
      current_path.should == keys_path
    end
  end

  describe "with project" do
    before do
      @project = Factory :project
      @project.add_access(@user, :read)
      visit project_path(@project)

      fill_in "search", :with => "Commi"
      sleep(2)
      find(:xpath, "//ul[contains(@class,'ui-autocomplete')]/li/a[.=\"#{@project.code} / Commits\"]").click
    end

    it "should be on projects page" do
      current_path.should == project_commits_path(@project)
    end
  end
end
