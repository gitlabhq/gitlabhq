# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- MCP tools share one endpoint
RSpec.describe API::Mcp, 'search_labels', :api, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, maintainers: [user]) }
  let_it_be(:label) { create(:label, project: project, title: 'backend-bug') }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true, mcp_server_enabled: true)
  end

  def call_search(search)
    post api('/mcp', user, oauth_access_token: access_token), params: {
      jsonrpc: '2.0', method: 'tools/call', id: '1',
      params: { name: 'search_labels', arguments: { full_path: project.full_path, is_project: true, search: search } }
    }, as: :json

    expect(response).to have_gitlab_http_status(:ok)
    json_response.fetch('result')
  end

  it 'accepts existing scalar search calls without version selection' do
    result = call_search('bug')

    expect(result['isError']).to be(false)
    expect(result.dig('structuredContent', 'items')).to include(a_hash_including('id' => label.to_global_id.to_s))
  end

  it 'accepts batch search calls without version selection' do
    result = call_search(%w[backend bug])

    expect(result['isError']).to be(false)
    expect(result.dig('structuredContent', 'items').map { |item| item['id'] }).to eq([label.to_global_id.to_s])
  end

  it 'advertises both input shapes in the latest tool schema' do
    post api('/mcp', user, oauth_access_token: access_token),
      params: { jsonrpc: '2.0', method: 'tools/list', id: '1' }

    expect(response).to have_gitlab_http_status(:ok)
    search_tool = json_response.dig('result', 'tools').find { |tool| tool['name'] == 'search_labels' }
    expect(search_tool.dig('inputSchema', 'properties', 'search', 'oneOf')).to eq([
      { 'type' => 'string' },
      { 'type' => 'array', 'items' => { 'type' => 'string' }, 'minItems' => 1, 'maxItems' => 10 }
    ])
  end

  it 'rejects a non-string scalar search term' do
    result = call_search(3)

    expect(result['isError']).to be(true)
    expect(result['content'].first['text']).to include('search is invalid')
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
