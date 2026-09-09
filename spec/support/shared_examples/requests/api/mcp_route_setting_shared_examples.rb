# frozen_string_literal: true

# Consuming specs must define `user` for the mcp-scoped token test.
RSpec.shared_examples 'an endpoint with mcp route setting' do |expected_tool, expected_params: nil, status: :ok|
  it 'has the correct mcp route setting configured' do
    subject # trigger the request defined in the including spec

    expect(response).to have_gitlab_http_status(status)

    endpoint = request.env['api.endpoint']
    actual_value = endpoint.route_setting(:mcp)

    expect(actual_value).to be_present
    expect(actual_value[:tool_name]).to eq(expected_tool.to_sym)
    expect(actual_value[:params]).to eq(expected_params) if expected_params
  end

  it 'accepts an mcp-scoped token', :aggregate_failures do
    subject

    mcp_token = create(:oauth_access_token, user: user, scopes: [:mcp])
    http_method = request.request_method.downcase.to_sym
    query_params = request.query_parameters.except('private_token', 'access_token', 'job_token')
    query_params['access_token'] = mcp_token.plaintext_token
    mcp_path = "#{request.path}?#{query_params.to_query}"

    send(http_method, mcp_path, params: request.request_parameters)

    expect(response).not_to have_gitlab_http_status(:forbidden)
    expect(response.body).not_to include('insufficient_scope')
  end
end
