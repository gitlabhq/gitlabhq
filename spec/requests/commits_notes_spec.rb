require 'spec_helper'

describe "Issues" do
  let(:project) { Factory :project }
  let!(:commit) { project.repo.commits.first }

  before do
    login_as :user
    project.add_access(@user, :read, :write)
  end

  describe "add new note", :js => true do
    before do
      visit project_commit_path(project, commit)
      fill_in "note_note", :with => "I commented this commit"
      click_button "Add note"
    end

    it "should conatin new note" do
      page.should have_content("I commented this commit")
    end

    it "should be displayed when i visit this commit again" do 
      visit project_commit_path(project, commit)
      page.should have_content("I commented this commit")
    end
  end
end
