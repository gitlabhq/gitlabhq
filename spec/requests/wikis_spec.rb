require 'spec_helper'

describe "Wiki" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :read, :write)
  end

  describe "Add pages" do
    before do
      visit project_wiki_path(project, :index)
    end

    it "should see form" do
      page.should have_content("Editing page")
    end

    it "should see added page" do
      fill_in "Title", :with => 'Test title'
      fill_in "Content", :with => '[link test](test)'
      click_on "Save"

      page.should have_content("Test title")
      page.should have_content("link test")

      click_link "link test"

      page.should have_content("Editing page")
    end

  end

end
