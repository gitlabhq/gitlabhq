# frozen_string_literal: true

module Features
  module DomHelpers
    def find_by_testid(testid, **kwargs)
      page.find("[data-testid='#{testid}']", **kwargs)
    end

    def within_testid(testid, &block)
      page.within("[data-testid='#{testid}']", &block)
    end
  end
end
