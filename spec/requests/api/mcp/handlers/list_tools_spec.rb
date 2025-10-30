# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat -- JSON-RPC has single path for method invocation
RSpec.describe API::Mcp, 'List tools request', feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:access_token) { create(:oauth_access_token, user: user, scopes: [:mcp]) }

  before do
    stub_application_setting(instance_level_ai_beta_features_enabled: true)
  end

  describe 'POST /mcp with tools/list method' do
    let(:params) do
      {
        jsonrpc: '2.0',
        method: 'tools/list',
        id: '1'
      }
    end

    def post_list_tools
      post api('/mcp', user, oauth_access_token: access_token), params: params
    end

    it 'returns success' do
      post_list_tools

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['jsonrpc']).to eq(params[:jsonrpc])
      expect(json_response['id']).to eq(params[:id])
      expect(json_response.keys).to include('result')
    end

    it 'returns all expected tools' do
      post_list_tools

      tools = json_response['result']['tools']
      tool_names = tools.pluck('name')

      expect(tool_names).to include(
        'get_pipeline_jobs',
        'gitlab_search',
        'get_issue',
        'create_issue',
        'create_merge_request',
        'get_merge_request',
        'get_merge_request_commits',
        'get_merge_request_diffs',
        'get_merge_request_pipelines',
        'get_mcp_server_version'
      )
    end

    context 'when a service tool is not available' do
      before do
        # We have to use `allow_any_instance_of` since tools are initialized
        # *on class definition time* in Mcp::Tools::Manager
        allow_any_instance_of(::Mcp::Tools::GetServerVersionService).to receive(:available?).and_return(false) # rubocop: disable RSpec/AnyInstanceOf -- see explanation above
      end

      it 'is excluded from the list' do
        post_list_tools

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).not_to include('get_mcp_server_version')
      end
    end

    context 'when running with EE features', if: Gitlab.ee? do
      it 'validates that fields parameter is available' do
        post_list_tools

        tools = json_response['result']['tools']
        gitlab_search_tool = tools.find { |tool| tool['name'] == 'gitlab_search' }

        fields_property = gitlab_search_tool['inputSchema']['properties']['fields']

        expect(fields_property).to be_present
        expect(fields_property['type']).to eq('string')
      end
    end

    context 'when running CE', unless: Gitlab.ee? do
      before do
        post_list_tools
      end

      it 'returns get_pipeline_jobs tool with correct structure' do
        tools = json_response['result']['tools']
        pipeline_jobs_tool = tools.find { |tool| tool['name'] == 'get_pipeline_jobs' }

        expect(pipeline_jobs_tool).to include(
          'name' => 'get_pipeline_jobs',
          'description' => 'Get pipeline jobs',
          'inputSchema' => {
            'type' => 'object',
            'properties' => {
              'id' => {
                'type' => 'string',
                'description' => 'The project ID or URL-encoded path'
              },
              'pipeline_id' => {
                'type' => 'integer',
                'description' => 'The pipeline ID'
              },
              'per_page' => {
                'type' => 'integer',
                'description' => 'Number of items per page'
              },
              'page' => {
                'type' => 'integer',
                'description' => 'Current page number'
              }
            },
            'required' => %w[id pipeline_id],
            'additionalProperties' => false
          }
        )
      end

      it 'returns get_issue tool with correct structure' do
        tools = json_response['result']['tools']
        get_issue_tool = tools.find { |tool| tool['name'] == 'get_issue' }

        expect(get_issue_tool).to include(
          'name' => 'get_issue',
          'description' => 'Get a single project issue',
          'inputSchema' => {
            'type' => 'object',
            'properties' => {
              'id' => {
                'type' => 'string',
                'description' => 'The ID or URL-encoded path of the project'
              },
              'issue_iid' => {
                'type' => 'integer',
                'description' => 'The internal ID of a project issue'
              }
            },
            'required' => %w[id issue_iid],
            'additionalProperties' => false
          }
        )
      end

      it 'returns create_issue tool with correct structure' do
        tools = json_response['result']['tools']
        create_issue_tool = tools.find { |tool| tool['name'] == 'create_issue' }

        expect(create_issue_tool).to include(
          'name' => 'create_issue',
          'description' => 'Create a new project issue'
        )
        expect(create_issue_tool['inputSchema']).to include(
          'type' => 'object',
          'required' => %w[id title],
          'additionalProperties' => false
        )
        expect(create_issue_tool['inputSchema']['properties']).to include(
          'id' => { 'type' => 'string', 'description' => 'The ID or URL-encoded path of the project' },
          'title' => { 'type' => 'string', 'description' => 'The title of an issue' }
        )
      end

      it 'returns get_merge_request tool with correct structure' do
        tools = json_response['result']['tools']
        get_merge_request_tool = tools.find { |tool| tool['name'] == 'get_merge_request' }

        expect(get_merge_request_tool).to include(
          'name' => 'get_merge_request',
          'description' => 'Get single merge request',
          'inputSchema' => {
            'type' => 'object',
            'properties' => {
              'id' => {
                'type' => 'string',
                'description' => 'The ID or URL-encoded path of the project.'
              },
              'merge_request_iid' => {
                'type' => 'integer',
                'description' => 'The internal ID of the merge request.'
              }
            },
            'required' => %w[id merge_request_iid],
            'additionalProperties' => false
          }
        )
      end

      it 'returns get_merge_request_commits tool with correct structure' do
        tools = json_response['result']['tools']
        get_mr_commits_tool = tools.find { |tool| tool['name'] == 'get_merge_request_commits' }

        expect(get_mr_commits_tool).to include(
          'name' => 'get_merge_request_commits',
          'description' => 'Get single merge request commits'
        )
        expect(get_mr_commits_tool['inputSchema']).to include(
          'type' => 'object',
          'required' => %w[id merge_request_iid],
          'additionalProperties' => false
        )
        expect(get_mr_commits_tool['inputSchema']['properties']).to include(
          'id' => { 'type' => 'string', 'description' => 'The ID or URL-encoded path of the project.' },
          'merge_request_iid' => { 'type' => 'integer', 'description' => 'The internal ID of the merge request.' }
        )
      end

      it 'returns get_merge_request_diffs tool with correct structure' do
        tools = json_response['result']['tools']
        get_mr_diffs_tool = tools.find { |tool| tool['name'] == 'get_merge_request_diffs' }

        expect(get_mr_diffs_tool).to include(
          'name' => 'get_merge_request_diffs',
          'description' => 'Get the merge request diffs'
        )
        expect(get_mr_diffs_tool['inputSchema']).to include(
          'type' => 'object',
          'required' => %w[id merge_request_iid],
          'additionalProperties' => false
        )
        expect(get_mr_diffs_tool['inputSchema']['properties']).to include(
          'id' => { 'type' => 'string', 'description' => 'The ID or URL-encoded path of the project.' },
          'merge_request_iid' => { 'type' => 'integer', 'description' => 'The internal ID of the merge request.' }
        )
      end

      it 'returns get_merge_request_pipelines tool with correct structure' do
        tools = json_response['result']['tools']
        get_mr_pipelines_tool = tools.find { |tool| tool['name'] == 'get_merge_request_pipelines' }

        expect(get_mr_pipelines_tool).to include(
          'name' => 'get_merge_request_pipelines',
          'description' => 'Get single merge request pipelines',
          'inputSchema' => {
            'type' => 'object',
            'properties' => {
              'id' => {
                'type' => 'string',
                'description' => 'The ID or URL-encoded path of the project.'
              },
              'merge_request_iid' => {
                'type' => 'integer',
                'description' => 'The internal ID of the merge request.'
              }
            },
            'required' => %w[id merge_request_iid],
            'additionalProperties' => false
          }
        )
      end

      it 'returns get_mcp_server_version tool with correct structure' do
        tools = json_response['result']['tools']
        version_tool = tools.find { |tool| tool['name'] == 'get_mcp_server_version' }

        expect(version_tool).to include(
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
end
# rubocop:enable RSpec/SpecFilePathFormat
