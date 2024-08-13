# frozen_string_literal: true

module Features
  module DomHelpers
    def has_testid?(testid, context: page, **kwargs)
      context.has_selector?("[data-testid='#{testid}']", **kwargs)
    end

    def find_by_testid(testid, context: page, **kwargs)
      context.find("[data-testid='#{testid}']", **kwargs)
    end

    def all_by_testid(testid, context: page, **kwargs)
      context.all("[data-testid='#{testid}']", **kwargs)
    end

    def within_testid(testid, context: page, **kwargs, &block)
      context.within("[data-testid='#{testid}']", **kwargs, &block)
    end

    def page_breadcrumbs
      all('[data-testid=breadcrumb-links] a').map do |a|
        # We use `.dom_attribute` because Selenium transforms `.attribute('href')` to include the full URL.
        { text: a.text, href: a.native.dom_attribute('href') }
      end
    end
  end
end
