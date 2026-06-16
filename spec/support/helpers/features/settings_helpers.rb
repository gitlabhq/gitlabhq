# frozen_string_literal: true

module Features
  module SettingsHelpers
    # The refresh parameter triggers a page refresh after save to remove the URL fragment,
    # so that subsequent submissions within the same test can be properly detected.
    def expect_save_settings(button_text: _('Save changes'), refresh: false)
      # Before the POST the URL doesn't contain a fragment, /path
      expect(page).not_to have_current_path(/#/, url: true),
        'Expected URL not to contain a fragment (`#`) before the saving. ' \
          'Use the `refresh` parameter for multiple savings within the same test.'

      click_button button_text

      # After the POST the URL contains a fragment, /path#js-something
      expect(page).to have_current_path(/#/, url: true)

      visit current_url.split('#').first if refresh
    end

    def choose_option(option_name)
      expect(find_field(option_name)).not_to be_checked
      choose option_name
    end

    def click_unchecked_field(field_name)
      expect(find_field(field_name)).not_to be_checked
      find_field(field_name).click
    end

    def expect_field_checked(field_name)
      expect(find_field(field_name)).to be_checked
    end

    def click_checked_field(field_name)
      expect(find_field(field_name)).to be_checked
      find_field(field_name).click
    end

    def expect_field_unchecked(field_name)
      expect(find_field(field_name)).not_to be_checked
    end

    def fill_field_with_new_value(field_name, value)
      expect(find_field(field_name).value).not_to eq(value)
      fill_in field_name, with: value
    end

    def expect_field_value(field_name, value)
      expect(find_field(field_name).value).to eq(value)
    end

    private

    def current_settings
      ApplicationSetting.current_without_cache
    end
  end
end
