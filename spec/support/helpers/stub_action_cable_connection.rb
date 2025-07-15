# frozen_string_literal: true

module StubActionCableConnection
  def stub_action_cable_connection(
    current_user: nil,
    access_token: nil,
    request: ActionDispatch::TestRequest.create,
    current_organization: nil
  )
    request.headers['Authorization'] = "Bearer #{access_token.token}" if access_token
    stub_connection(current_user: current_user, request: request, current_organization: current_organization)
  end
end
