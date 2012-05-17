require 'spec_helper'

describe "Blame file" do
  before { login_as :user }

  describe "GET /:projectname/:commit/blob/Gemfile" do
    before do
      @project = Factory :project
      @project.add_access(@user, :read)

      visit tree_project_ref_path(@project, @project.root_ref, :path => "Gemfile")
      click_link "blame"
    end

    it "should be correct path" do
      current_path.should == blame_file_project_ref_path(@project, @project.root_ref, :path => "Gemfile")
    end

    it "should contain file view" do
      page.should have_content("rubygems.org")
      page.should have_content("Dmitriy Zaporozhets")
      page.should have_content("bc3735004cb Moving to rails 3.2")
    end
  end
end
