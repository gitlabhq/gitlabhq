require 'spec_helper'

describe "Search" do
  before do
    login_as :user
    @project = create(:project)
    @project.team << [@user, :reporter]
    visit search_path
    fill_in "search", with: @project.name[0..3]
    click_button "Search"
  end

  it "should show project in search results" do
    page.should have_content @project.name
  end
end

