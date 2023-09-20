# frozen_string_literal: true

# This helper allows you to reliably highlight text within a given Element by
# simulating mouse actions.
#
module Features
  module HighlightContentHelper
    def highlight_content(node)
      height = node.native.rect.height
      width = node.native.rect.width
      page.driver.browser.action
        .move_to(node.native, -(width / 2), -(height / 2))
        .click_and_hold
        .move_by(width, height)
        .release
        .perform
    end
  end
end
