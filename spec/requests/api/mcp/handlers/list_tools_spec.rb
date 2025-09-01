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
      skip if Gitlab.ee?

      expect(json_response['result']['tools']).to contain_exactly(
        {
          "name" => "get_pipeline_jobs",
          "description" => "Get pipeline jobs",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The project ID or URL-encoded path"
              }, "pipeline_id" => {
                "type" => "integer", "description" => "The pipeline ID"
              }, "per_page" => {
                "type" => "integer", "description" => "Number of items per page"
              }, "page" => {
                "type" => "integer", "description" => "Current page number"
              }
            }, "required" => %w[id pipeline_id], "additionalProperties" => false
          }
        }, {
          "name" => "get_issue",
          "description" => "Get a single project issue",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The ID or URL-encoded path of the project"
              }, "issue_iid" => {
                "type" => "integer", "description" => "The internal ID of a project issue"
              }
            }, "required" => %w[id issue_iid], "additionalProperties" => false
          }
        }, {
          "name" => "create_issue",
          "description" => "Create a new project issue",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The ID or URL-encoded path of the project"
              }, "title" => {
                "type" => "string", "description" => "The title of an issue"
              }, "description" => {
                "type" => "string", "description" => "The description of an issue"
              }, "assignee_ids" => {
                "type" => "array", "description" => "The array of user IDs to assign issue"
              }, "milestone_id" => {
                "type" => "integer", "description" => "The ID of a milestone to assign issue"
              }, "labels" => {
                "type" => "string", "description" => "Comma-separated list of label names"
              }, "confidential" => {
                "type" => "boolean", "description" => "Boolean parameter if the issue should be confidential"
              }
            }, "required" => %w[id title], "additionalProperties" => false
          }
        }, {
          "name" => "get_merge_request",
          "description" => "Get single merge request",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The ID or URL-encoded path of the project."
              }, "merge_request_iid" => {
                "type" => "integer", "description" => "The internal ID of the merge request."
              }
            }, "required" => %w[id merge_request_iid], "additionalProperties" => false
          }
        }, {
          "name" => "get_merge_request_commits",
          "description" => "Get single merge request commits",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The ID or URL-encoded path of the project."
              }, "merge_request_iid" => {
                "type" => "integer", "description" => "The internal ID of the merge request."
              }, "per_page" => {
                "type" => "integer", "description" => "Number of items per page"
              }, "page" => {
                "type" => "integer", "description" => "Current page number"
              }
            }, "required" => %w[id merge_request_iid], "additionalProperties" => false
          }
        }, {
          "name" => "get_merge_request_diffs",
          "description" => "Get the merge request diffs",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The ID or URL-encoded path of the project."
              }, "merge_request_iid" => {
                "type" => "integer", "description" => "The internal ID of the merge request."
              }, "per_page" => {
                "type" => "integer", "description" => "Number of items per page"
              }, "page" => {
                "type" => "integer", "description" => "Current page number"
              }
            }, "required" => %w[id merge_request_iid], "additionalProperties" => false
          }
        }, {
          "name" => "get_merge_request_pipelines",
          "description" => "Get single merge request pipelines",
          "inputSchema" => {
            "type" => "object", "properties" => {
              "id" => {
                "type" => "string", "description" => "The ID or URL-encoded path of the project."
              }, "merge_request_iid" => {
                "type" => "integer", "description" => "The internal ID of the merge request."
              }
            }, "required" => %w[id merge_request_iid], "additionalProperties" => false
          }
        }, {
          "name" => "get_mcp_server_version",
          "description" => "Get the current version of MCP server.",
          "inputSchema" => {
            "type" => "object", "properties" => {}, "required" => []
          }
        }
      )
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
