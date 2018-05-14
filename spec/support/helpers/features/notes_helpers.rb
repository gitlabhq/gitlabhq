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
            Sidekiq::Testing.fake! do
              page.within(".js-main-target-form") do
                fill_in("note[note]", with: text)
                find(".js-comment-submit-button").click
              end
            end
          end
        end
      end
    end
  end
end
