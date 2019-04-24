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

              begin
                # Dismiss quick action prompt if it appears
                filled_text.parent.send_keys(:escape)
              rescue Selenium::WebDriver::Error::ElementNotInteractableError
                # It's fine if we can't escape when there's no prompt.
              end

              click_on('Preview')

              yield if block_given?
            end
          end
        end
      end
    end
  end
end
