# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'List tools request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  describe 'POST /mcp_server with tools/list method' do
    let(:params) do
      {
        jsonrpc: '2.0',
        method: 'tools/list',
        id: '1'
      }
    end

    before do
      post api('/mcp_server', user, oauth_access_token: access_token), params: params
    end

    it 'returns success' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['jsonrpc']).to eq(params[:jsonrpc])
      expect(json_response['id']).to eq(params[:id])
      expect(json_response.keys).to include('result')
    end

    it 'returns tools' do
      expect(json_response['result']['tools']).to eq([
        {
          "name" => "get_issue",
          "description" => "Get a single project issue",
          "inputSchema" => {
            "additionalProperties" => false,
            "properties" => {
              "id" => { "description" => "The ID or URL-encoded path of the project", "type" => "string" },
              "issue_iid" => { "description" => "The internal ID of a project issue", "type" => "integer" }
            },
            "required" => %w[id issue_iid],
            "type" => "object"
          }
        },
        {
          "name" => "get_merge_request",
          "description" => "Get single merge request",
          "inputSchema" => {
            "additionalProperties" => false,
            "properties" => {
              "id" => { "description" => "The ID or URL-encoded path of the project.", "type" => "string" },
              "merge_request_iid" => { "description" => "The internal ID of the merge request.", "type" => "integer" }
            },
            "required" => %w[id merge_request_iid],
            "type" => "object"
          }
        },
        {
          "name" => "get_mcp_server_version",
          "description" => "Get the current version of MCP server.",
          "inputSchema" => {
            "properties" => {},
            "required" => [],
            "type" => "object"
          }
        }
      ])
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
