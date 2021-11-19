# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module ModalHelpers
        def within_modal
          page.within('[role="dialog"]') do
            yield
          end
        end

        def accept_gl_confirm(text = nil, button_text: 'OK')
          yield if block_given?

          within_modal do
            unless text.nil?
              expect(page).to have_content(text)
            end

            click_button button_text
          end
        end
      end
    end
  end
end
