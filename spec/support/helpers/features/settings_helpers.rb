# frozen_string_literal: true

module Features
  module SettingsHelpers
    # Clicks a save button within the given selector and expects a redirect with a URL fragment.
    # If the selector starts with '#', '.', or '[', it is treated as a CSS selector.
    # Otherwise, it is assumed to be a data-testid value.
    # The button_text parameter defaults to 'Save changes' but can be overridden
    # for sections with different button text, e.g. 'Save Default limits'.
    # The refresh parameter triggers a page refresh after save to remove the URL fragment,
    # so that subsequent submissions within the same test can be properly detected.
    def expect_save_settings(selector, button_text: _('Save changes'), refresh: false)
      # Before the POST the URL doesn't contain a fragment, /path
      expect(page).not_to have_current_path(/#/, url: true),
        'Expected URL not to contain a fragment (`#`) before the saving. ' \
          'Use the `refresh` parameter for multiple savings within the same test.'

      if selector.start_with?('#', '.', '[')
        within(selector) do
          click_button button_text
        end
      else
        within_testid(selector) do
          click_button button_text
        end
      end

      # After the POST the URL contains a fragment, /path#js-something
      expect(page).to have_current_path(/#/, url: true)

      visit current_url.split('#').first if refresh
    end
  end
end
