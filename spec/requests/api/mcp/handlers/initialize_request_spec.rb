# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'Initialize request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true)
  end

  describe 'POST /mcp with initialize method' do
    let(:params) do
      {
        jsonrpc: '2.0',
        method: 'initialize',
        id: '1'
      }
    end

    before do
      post api('/mcp', user, oauth_access_token: access_token), params: params
    end

    it 'returns success' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['jsonrpc']).to eq(params[:jsonrpc])
      expect(json_response['id']).to eq(params[:id])
      expect(json_response.keys).to include('result')
    end

    it 'returns protocol version' do
      expect(json_response['result']['protocolVersion']).to eq('2025-06-18')
    end

    it 'returns capabilities' do
      expect(json_response['result']['capabilities']).to include(
        'tools' => { 'listChanged' => false }
      )
    end

    it 'returns server info' do
      expect(json_response['result']['serverInfo']).to include(
        'name' => 'Official GitLab MCP Server',
        'version' => Gitlab::VERSION
      )
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
