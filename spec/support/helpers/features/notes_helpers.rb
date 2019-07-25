# frozen_string_literal: true

# These helpers allow you to manipulate with notes.
#
# Usage:
#   describe "..." do
#     include Spec::Support::Helpers::Features::NotesHelpers
#     ...
#
#     add_note("Hello world!")
#
module Spec
  module Support
    module Helpers
      module Features
        module NotesHelpers
          def add_note(text)
            perform_enqueued_jobs do
              page.within(".js-main-target-form") do
                fill_in("note[note]", with: text)
                find(".js-comment-submit-button").click
              end
            end
          end

          def preview_note(text)
            page.within('.js-main-target-form') do
              filled_text = fill_in('note[note]', with: text)

              # Wait for quick action prompt to load and then dismiss it with ESC
              # because it may block the Preview button
              wait_for_requests
              filled_text.send_keys(:escape)

              click_on('Preview')

              yield if block_given?
            end
          end
        end
      end
    end
  end
end
