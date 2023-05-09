# frozen_string_literal: true

require_relative 'helpers/capybara_helpers'
require_relative 'helpers/wait_for_requests'

module Capybara
  class Session
    module WaitForAllRequestsAfterVisitPage
      include CapybaraHelpers
      include WaitForRequests

      def visit(visit_uri)
        super

        wait_for_all_requests
      end
    end

    prepend WaitForAllRequestsAfterVisitPage
  end

  module Node
    module Actions
      include CapybaraHelpers
      include WaitHelpers
      include WaitForRequests

      module WaitForAllRequestsAfterClickButton
        def click_button(locator = nil, **options)
          super

          wait_for_all_requests
        end
      end

      prepend WaitForAllRequestsAfterClickButton
    end
  end
end
