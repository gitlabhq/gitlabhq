# frozen_string_literal: true

require_relative './wait_for_requests'

module InspectRequests
  extend self
  include WaitForRequests

  def inspect_requests(inject_headers: {})
    Gitlab::Testing::RequestInspectorMiddleware.log_requests!(inject_headers)

    yield

    wait_for_all_requests
    Gitlab::Testing::RequestInspectorMiddleware.requests
  ensure
    Gitlab::Testing::RequestInspectorMiddleware.stop_logging!
  end
end
