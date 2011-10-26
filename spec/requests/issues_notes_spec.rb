require 'spec_helper'

describe "Issues" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :read, :write)

    @issue = Factory :issue,
      :author => @user,
      :assignee => @user,
      :project => project
  end

  describe "add new note", :js => true do
    before do
      visit project_issue_path(project, @issue)
      fill_in "note_note", :with => "I commented this issue"
      click_button "Add note"
    end

    it "should conatin new note" do
      page.should have_content("I commented this issue")
    end
  end
end
