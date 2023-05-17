# frozen_string_literal: true

# These helpers allow you to manipulate with notes.
#
# Usage:
#   describe "..." do
#     include Features::NotesHelpers
#     ...
#
#     add_note("Hello world!")
#
module Features
  module NotesHelpers
    def add_note(text)
      perform_enqueued_jobs do
        page.within(".js-main-target-form") do
          fill_in("note[note]", with: text)
          find(".js-comment-submit-button").click
        end
      end

      wait_for_requests
    end

    def edit_note(note_text_to_edit, new_note_text)
      page.within('#notes-list li.note', text: note_text_to_edit) do
        find('.js-note-edit').click
        fill_in('note[note]', with: new_note_text)
        find('.js-comment-button').click
      end

      wait_for_requests
    end

    def preview_note(text)
      page.within('.js-main-target-form') do
        filled_text = fill_in('note[note]', with: text)

        # Wait for quick action prompt to load and then dismiss it with ESC
        # because it may block the Preview button
        wait_for_requests
        filled_text.send_keys(:escape)

        click_button("Preview")

        yield if block_given?
      end
    end
  end
end
