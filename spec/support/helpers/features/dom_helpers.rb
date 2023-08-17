# frozen_string_literal: true

module Features
  module DomHelpers
    def find_by_testid(testid)
      page.find("[data-testid='#{testid}']")
    end

    def within_testid(testid, &block)
      page.within("[data-testid='#{testid}']", &block)
    end
  end
end
