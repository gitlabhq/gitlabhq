require 'spec_helper'

describe "On a commit", js: true do
  let!(:project) { create(:project) }
  let!(:commit) { project.commit("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }

  before do
    login_as :user
    project.add_access(@user, :read, :write)

    visit project_commit_path(project, commit)
  end

  subject { page }

  describe "the note form" do
    # main target form creation
    it { should have_css(".js-main-target-form", visible: true, count: 1) }

    # button initalization
    it { within(".js-main-target-form") { should have_button("Add Comment") } }
    it { within(".js-main-target-form") { should_not have_link("Cancel") } }

    # notifiactions
    it { within(".js-main-target-form") { should have_unchecked_field("Project team") } }
    it { within(".js-main-target-form") { should have_checked_field("Commit author") } }

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
    it { within(".js-main-target-form") { should have_no_field("note[note]", with: "This is awesome!")  } }

    # return from preview
    it { within(".js-main-target-form") { should have_css(".js-note-preview", visible: false) } }
    it { within(".js-main-target-form") { should have_css(".js-note-text", visible: true) } }


    it "should be removable" do
      find(".js-note-delete").trigger("click")

      should_not have_css(".note")
    end
  end
end



describe "On a commit diff", js: true do
  let!(:project) { create(:project) }
  let!(:commit) { project.commit("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }

  before do
    login_as :user
    project.add_access(@user, :read, :write)

    visit project_commit_path(project, commit)
  end

  subject { page }

  describe "when adding a note" do
    before do
      find("#0_185_185.line_holder .js-add-diff-note-button").trigger("click")
    end

    describe "the notes holder" do
      it { should have_css("#0_185_185.line_holder + .js-temp-notes-holder") }

      it { within(".js-temp-notes-holder") { should have_css(".new_note") } }
    end

    describe "the note form" do
      # set up hidden fields correctly
      it { within(".js-temp-notes-holder") { find("#note_noteable_type").value.should == "Commit" } }
      it { within(".js-temp-notes-holder") { find("#note_noteable_id").value.should == "" } }
      it { within(".js-temp-notes-holder") { find("#note_commit_id").value.should == "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a" } }
      it { within(".js-temp-notes-holder") { find("#note_line_code").value.should == "0_185_185" } }

      # buttons
      it { should have_button("Add Comment") }
      it { should have_css(".js-close-discussion-note-form", text: "Cancel") }

      # notification options
      it { should have_unchecked_field("Project team") }
      it { should have_checked_field("Commit author") }

      it "shouldn't add a second form for same row" do
        find("#0_185_185.line_holder .js-add-diff-note-button").trigger("click")

        should have_css("#0_185_185.line_holder + .js-temp-notes-holder form", count: 1)
      end

      it "should be removed when canceled" do
        find(".js-close-discussion-note-form").trigger("click")

        should have_no_css(".js-temp-notes-holder")
      end
    end
  end

  describe "with muliple note forms" do
    before do
      find("#0_185_185.line_holder .js-add-diff-note-button").trigger("click")
      find("#1_18_17.line_holder .js-add-diff-note-button").trigger("click")
    end

    # has two line forms
    it { should have_css(".js-temp-notes-holder", count: 2) }

    describe "previewing them separately" do
      before do
        # add two separate texts and trigger previews on both
        within("#0_185_185.line_holder + .js-temp-notes-holder") do
          fill_in "note[note]", with: "One comment on line 185"
          find(".js-note-preview-button").trigger("click")
        end
        within("#1_18_17.line_holder + .js-temp-notes-holder") do
          fill_in "note[note]", with: "Another comment on line 17"
          find(".js-note-preview-button").trigger("click")
        end
      end

      # check if previews were rendered separately
      it { within("#0_185_185.line_holder + .js-temp-notes-holder") { should have_css(".js-note-preview", text: "One comment on line 185") } }
      it { within("#1_18_17.line_holder + .js-temp-notes-holder") { should have_css(".js-note-preview", text: "Another comment on line 17") } }
    end

    describe "posting a note" do
      before do
        within("#1_18_17.line_holder + .js-temp-notes-holder") do
          fill_in "note[note]", with: "Another comment on line 17"
          click_button("Add Comment")
        end
      end

      # removed form after submit
      it { should have_no_css("#1_18_17.line_holder + .js-temp-notes-holder") }

      # added discussion
      it { should have_content("Another comment on line 17") }
      it { should have_css("#1_18_17.line_holder + .notes_holder") }
      it { should have_css("#1_18_17.line_holder + .notes_holder .note", count: 1) }
      it { should have_link("Reply") }

      it "should remove last note of a discussion" do
        within("#1_18_17.line_holder + .notes_holder") do
          find(".js-note-delete").trigger("click")
        end

        # removed whole discussion
        should_not have_css(".note_holder")
        should have_css("#1_18_17.line_holder + #1_18_18.line_holder")
      end
    end
  end

  describe "when replying to a note" do
    before do
      # create first note
      find("#0_184_184.line_holder .js-add-diff-note-button").trigger("click")
      within("#0_184_184.line_holder + .js-temp-notes-holder") do
        fill_in "note[note]", with: "One comment on line 184"
        click_button("Add Comment")
      end
      # create second note
      within("#0_184_184.line_holder + .notes_holder") do
        find(".js-discussion-reply-button").trigger("click")
        fill_in "note[note]", with: "An additional comment in reply"
        click_button("Add Comment")
      end
    end

    # inserted note
    it { should have_content("An additional comment in reply") }
    it { within("#0_184_184.line_holder + .notes_holder") { should have_css(".note", count: 2) } }

    # removed form after reply
    it { within("#0_184_184.line_holder + .notes_holder") { should have_no_css("form") } }
    it { within("#0_184_184.line_holder + .notes_holder") { should have_link("Reply") } }
  end
end
 