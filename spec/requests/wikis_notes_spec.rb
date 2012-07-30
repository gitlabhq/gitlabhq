require 'spec_helper'

describe "Wikis" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :read, :write)
  end

  describe "add new note", :js => true do
    before do
      visit project_wiki_path(project, :index)
      
      fill_in "Title", :with => 'Test title'
      fill_in "Content", :with => '[link test](test)'
      click_on "Save"
      
      page.should have_content("Test title")
      
      fill_in "note_note", :with => "Comment on wiki!"
      click_button "Add Comment"
    end

    it "should contain the new note" do
      page.should have_content("Comment on wiki!")
    end
  end
end
