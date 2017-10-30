require_relative './wait_for_requests'

module InspectRequests
  extend self
  include WaitForRequests

  def inspect_requests(inject_headers: {})
    Gitlab::Testing::RequestInspectorMiddleware.log_requests!(inject_headers)
    yield
    block_and_wait_for_requests_complete
    Gitlab::Testing::RequestInspectorMiddleware.requests
  ensure
    Gitlab::Testing::RequestInspectorMiddleware.stop_logging!
  end
end
