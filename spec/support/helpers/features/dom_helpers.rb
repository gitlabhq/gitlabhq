# frozen_string_literal: true

module Features
  module DomHelpers
    def page_breadcrumbs
      all('[data-testid=breadcrumb-links] a').map do |a|
        # We use `.dom_attribute` because Selenium transforms `.attribute('href')` to include the full URL.
        { text: a.text, href: a.native.dom_attribute('href') }
      end
    end
  end
end
