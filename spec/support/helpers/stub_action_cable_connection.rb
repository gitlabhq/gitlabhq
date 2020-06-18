# frozen_string_literal: true

module StubActionCableConnection
  def stub_action_cable_connection(current_user: nil, request: ActionDispatch::TestRequest.create)
    stub_connection(current_user: current_user, request: request)
  end
end
