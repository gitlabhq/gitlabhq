# frozen_string_literal: true

require_relative 'helpers/capybara_helpers'
require_relative 'helpers/wait_for_requests'

module Capybara
  class Session
    module WaitForRequestsAfterVisitPage
      include CapybaraHelpers
      include WaitForRequests

      def visit(visit_uri, &block)
        super

        yield if block

        wait_for_requests
      end
    end

    prepend WaitForRequestsAfterVisitPage
  end

  module Node
    module Actions
      include CapybaraHelpers
      include WaitForRequests

      module WaitForRequestsAfterClickButton
        def click_button(locator = nil, max_wait_time: 2 * Capybara.default_max_wait_time, **options)
          super(locator, **options)

          wait_for_requests(max_wait_time: max_wait_time)
        end
      end

      module WaitForRequestsAfterClickLink
        def click_link(locator = nil, **options, &block)
          super

          yield if block

          wait_for_requests
        end
      end

      prepend WaitForRequestsAfterClickButton
      prepend WaitForRequestsAfterClickLink
    end
  end
end
