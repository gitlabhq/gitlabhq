# frozen_string_literal: true

RSpec.shared_examples 'an endpoint with mcp route setting' do |expected_tool, expected_params = nil|
  it 'has the correct mcp route setting configured' do
    subject # trigger the request defined in the including spec

    expect(response).to have_gitlab_http_status(:ok)

    endpoint = request.env['api.endpoint']
    actual_value = endpoint.route_setting(:mcp)

    expect(actual_value).to be_present
    expect(actual_value[:tool_name]).to eq(expected_tool.to_sym)
    expect(actual_value[:params]).to eq(expected_params) if expected_params
  end
end
