require 'spec_helper'

describe "Hooks" do
  before do
    login_as :user
    @project = Factory :project
    @project.add_access(@user, :read, :admin)
  end

  describe "GET index" do
    it "should be available" do
      @hook = Factory :project_hook, project: @project
      visit project_hooks_path(@project)
      page.should have_content "Hooks"
      page.should have_content @hook.url
    end
  end

  describe "New Hook" do
    before do
      @url = Faker::Internet.uri("http")
      visit project_hooks_path(@project)
      fill_in "hook_url", with: @url
      expect { click_button "Add Web Hook" }.to change(ProjectHook, :count).by(1)
    end

    it "should open new team member popup" do
      page.current_path.should == project_hooks_path(@project)
      page.should have_content(@url)
    end
  end

  describe "Test" do
    before do
      @hook = Factory :project_hook, project: @project
      stub_request(:post, @hook.url)
      visit project_hooks_path(@project)
      click_link "Test Hook"
    end

    it { page.current_path.should == project_hooks_path(@project) }
  end
end
