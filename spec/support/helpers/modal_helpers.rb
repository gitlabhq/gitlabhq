# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      module ModalHelpers
        MODAL_SELECTOR = '[role="dialog"]'

        def within_modal
          page.within(MODAL_SELECTOR) do
            yield
          end
        end

        def accept_gl_confirm(text = nil, button_text: 'OK')
          yield if block_given?

          # Wait for the modal's show transition to finish, avoiding a stale node race
          # with GlModal's async lazy render.
          expect(page).to have_css("#{MODAL_SELECTOR}.show")

          within_modal do
            expect(page).to have_content(text) if text
            expect(page).to have_button(button_text) if button_text
            click_button button_text
          end

          expect(page).to have_no_selector(MODAL_SELECTOR)
        end
      end
    end
  end
end
