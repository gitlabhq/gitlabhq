# frozen_string_literal: true

module TestRequestHelpers
  def test_request(remote_ip: '127.0.0.1', controller: nil)
    ActionController::TestRequest.new({ remote_ip: remote_ip }, ActionController::TestSession.new, controller)
  end
end
