# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'List tools request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  before do
    stub_feature_flags(mcp_server_new_implementation: false)
  end

  describe 'POST /mcp with tools/list method' do
    let(:params) do
      {
        jsonrpc: '2.0',
        method: 'tools/list',
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

    it 'returns tools' do
      expect(json_response['result']['tools']).to be_an(Array)
    end

    it 'returns tool with structured values' do
      mock_tool = json_response['result']['tools'].first

      expect(mock_tool).to include(
        'name' => 'get_mcp_server_version',
        'description' => 'Get the current version of MCP server.',
        'inputSchema' => {
          'type' => 'object',
          'properties' => {},
          'required' => []
        }
      )
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
