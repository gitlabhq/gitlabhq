# frozen_string_literal: true

# These helpers allow you to set up mirroring.
#
# Usage:
#   describe "..." do
#     include Features::MirroringHelpers
#     ...
#
#     fill_and_wait_for_mirror_url_javascript("url", "ssh://user@localhost/project.git")
#     wait_for_mirror_field_javascript("protected", "0")
#
module Features
  module MirroringHelpers
    # input_identifier - identifier of the input field, passed to `fill_in` (can be an ID or a label).
    # url - the URL to fill the input field with.
    def fill_and_wait_for_mirror_url_javascript(input_identifier, url)
      fill_in input_identifier, with: url
      wait_for_mirror_field_javascript('url', url)
    end

    # attribute - can be `url` or `protected`. It's used in the `.js-mirror-<field>-hidden` selector.
    # expected_value - the expected value of the hidden field.
    def wait_for_mirror_field_javascript(attribute, expected_value)
      expect(page).to have_css(".js-mirror-#{attribute}-hidden[value=\"#{expected_value}\"]", visible: :hidden)
    end
  end
end
