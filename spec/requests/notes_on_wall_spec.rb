require 'spec_helper'

describe "On the project wall", js: true do
  let!(:project) { create(:project) }
  let!(:commit) { project.repository.commit("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }

  before do
    login_as :user
    project.team << [@user, :master]
    visit wall_project_path(project)
  end

  subject { page }

  describe "the note form" do
    # main target form creation
    it { should have_css(".js-main-target-form", visible: true, count: 1) }

    # button initalization
    it { within(".js-main-target-form") { should have_button("Add Comment") } }
    it { within(".js-main-target-form") { should_not have_link("Cancel") } }

    # notifiactions
    it { within(".js-main-target-form") { should have_checked_field("Notify team via email") } }
    it { within(".js-main-target-form") { should_not have_checked_field("Notify commit author") } }
    it { within(".js-main-target-form") { should_not have_unchecked_field("Notify commit author") } }

    describe "without text" do
      it { within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: false) } }
    end

    describe "with text" do
      before do
        within(".js-main-target-form") do
          fill_in "note[note]", with: "This is awesome"
        end
      end

      it { within(".js-main-target-form") { should_not have_css(".js-comment-button[disabled]") } }

      it { within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: true) } }
    end

    describe "with preview" do
      before do
        within(".js-main-target-form") do
          fill_in "note[note]", with: "This is awesome"
          find(".js-note-preview-button").trigger("click")
        end
      end

      it { within(".js-main-target-form") { should have_css(".js-note-preview", text: "This is awesome", visible: true) } }

      it { within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: false) } }
      it { within(".js-main-target-form") { should have_css(".js-note-edit-button", visible: true) } }
    end
  end

  describe "when posting a note" do
    before do
      within(".js-main-target-form") do
        fill_in "note[note]", with: "This is awsome!"
        find(".js-note-preview-button").trigger("click")
        click_button "Add Comment"
      end
    end

    # note added
    it { within(".js-main-target-form") { should have_content("This is awsome!") } }

    # reset form
    it { within(".js-main-target-form") { should have_no_field("note[note]", with: "This is awesome!") } }

    # return from preview
    it { within(".js-main-target-form") { should have_css(".js-note-preview", visible: false) } }
    it { within(".js-main-target-form") { should have_css(".js-note-text", visible: true) } }


    it "should be removable" do
      find(".js-note-delete").trigger("click")

      should_not have_css(".note")
    end
  end
end
