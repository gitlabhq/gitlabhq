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

    it 'returns tools' do
      post_list_tools

      expect(json_response['result']['tools']).to be_present
    end

    it 'registers and surfaces every MCP tool service defined in the codebase', :eager_load, :aggregate_failures do
      defined_tools = Mcp::Tools::Base::BaseService.descendants
        .reject { |klass| klass.superclass == Mcp::Tools::Base::BaseService }

      expect(defined_tools).not_to be_empty, 'No MCP tool services were discovered'

      surfaced_tools = Mcp::Tools::Manager.new.list_tools.values.map(&:class)

      unregistered = defined_tools - surfaced_tools

      expect(unregistered).to be_empty,
        "Tool services defined but not registered in Mcp::Tools::Manager: #{unregistered.map(&:name).join(', ')}"
    end

    it 'locks each tool to its publicly-contracted annotations', :aggregate_failures, unless: Gitlab.ee? do
      post_list_tools

      expected_annotations = {
        # write, non-destructive
        'create_issue' => { 'readOnlyHint' => false, 'destructiveHint' => false },
        'create_merge_request' => { 'readOnlyHint' => false, 'destructiveHint' => false },
        'create_merge_request_note' => { 'readOnlyHint' => false, 'destructiveHint' => false },
        'create_workitem_note' => { 'readOnlyHint' => false, 'destructiveHint' => false },
        'link_work_items' => { 'readOnlyHint' => false, 'destructiveHint' => false },
        # write, destructive
        'manage_pipeline' => { 'readOnlyHint' => false, 'destructiveHint' => true },
        # read-only
        'get_issue' => { 'readOnlyHint' => true },
        'get_job_log' => { 'readOnlyHint' => true },
        'get_mcp_server_version' => { 'readOnlyHint' => true },
        'get_merge_request' => { 'readOnlyHint' => true },
        'get_merge_request_commits' => { 'readOnlyHint' => true },
        'get_merge_request_conflicts' => { 'readOnlyHint' => true },
        'get_merge_request_diffs' => { 'readOnlyHint' => true },
        'get_merge_request_notes' => { 'readOnlyHint' => true },
        'get_merge_request_pipelines' => { 'readOnlyHint' => true },
        'get_pipeline_jobs' => { 'readOnlyHint' => true },
        'get_saved_view_work_items' => { 'readOnlyHint' => true },
        'get_work_item_types' => { 'readOnlyHint' => true },
        'get_workitem_notes' => { 'readOnlyHint' => true },
        'search' => { 'readOnlyHint' => true },
        'search_labels' => { 'readOnlyHint' => true }
      }

      actual_annotations = json_response['result']['tools'].to_h { |tool| [tool['name'], tool['annotations']] }

      expect(actual_annotations.keys).to match_array(expected_annotations.keys)
      expect(actual_annotations).to eq(expected_annotations)
    end

    it 'surfaces every MCP-enabled API endpoint as a tool', :aggregate_failures do
      post_list_tools

      api_tool_names = ::API::API.routes.filter_map do |route|
        settings = route.app.route_setting(:mcp)
        next if settings.blank? || settings[:aggregators].present?

        settings[:tool_name].to_s
      end.uniq

      surfaced_names = json_response['result']['tools'].pluck('name')

      expect(api_tool_names).not_to be_empty, 'No MCP-enabled API routes were discovered'
      expect(surfaced_names).to include(*api_tool_names)
    end

    it 'validates all array parameters have proper JSON Schema structure with items property' do
      post api('/mcp', user, oauth_access_token: access_token), params: params

      tools = json_response['result']['tools']

      tools.each do |tool|
        tool_name = tool['name']
        properties = tool.dig('inputSchema', 'properties') || {}

        properties.each do |param_name, param_schema|
          next unless param_schema['type'] == 'array'

          expect(param_schema).to have_key('items'),
            "Tool '#{tool_name}' has array parameter '#{param_name}' without 'items' property. " \
              "JSON Schema requires array types to specify what's in the array using the 'items' property. " \
              "Current schema: #{param_schema.inspect}"

          expect(param_schema['items']).to have_key('type'),
            "Tool '#{tool_name}' has array parameter '#{param_name}' with 'items' but missing 'type' in items. " \
              "Current schema: #{param_schema.inspect}"
        end
      end
    end

    it 'exposes a well-formed JSON Schema envelope for every tool' do
      post_list_tools

      tools = json_response['result']['tools']
      expect(tools).not_to be_empty, 'No tools returned'

      tools.each do |tool|
        name = tool['name']
        schema = tool['inputSchema']

        expect(schema['type']).to eq('object'),
          "Tool '#{name}' inputSchema 'type' must be 'object': #{schema.inspect}"
        expect(schema['properties']).to be_a(Hash),
          "Tool '#{name}' inputSchema 'properties' must be an object: #{schema.inspect}"

        expect(schema['required']).to be_an(Array) if schema.key?('required')
        expect(schema['additionalProperties']).to be_in([true, false]) if schema.key?('additionalProperties')
      end
    end

    it 'includes icon for all tools' do
      post_list_tools

      tools = json_response['result']['tools']

      expect(tools).not_to be_empty, 'No tools returned'

      expected_icon = Mcp::Tools::IconConfig.gitlab_icons.first.stringify_keys

      tools.each do |tool|
        expect(tool).to have_key('icons')
        expect(tool['icons']).to be_an(Array)
        expect(tool['icons'].length).to eq(1)
        expect(tool['icons'].first).to eq(expected_icon)
      end
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

    context 'when x-gitlab-enabled-mcp-server-tools header is present' do
      def post_list_tools_with_allowed(allowed_tools)
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Enabled-Mcp-Server-Tools' => allowed_tools }
      end

      it 'returns only the tools listed in the header' do
        post_list_tools_with_allowed('get_issue,create_issue')

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to contain_exactly('get_issue', 'create_issue')
      end

      it 'excludes tools not in the allowed list' do
        post_list_tools_with_allowed('get_issue')

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).not_to include('create_issue', 'search', 'get_merge_request')
      end

      it 'handles a single tool correctly' do
        post_list_tools_with_allowed('search')

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to contain_exactly('search')
      end

      it 'returns an empty tool list when no allowed tools match' do
        post_list_tools_with_allowed('nonexistent_tool')

        tools = json_response['result']['tools']
        expect(tools).to be_empty
      end

      context 'when the header is blank' do
        it 'returns all available tools' do
          post_list_tools_with_allowed('')

          tool_names = json_response['result']['tools'].pluck('name')
          expect(tool_names).to include('get_issue', 'create_issue', 'search', 'get_merge_request')
        end
      end
    end

    context 'when x-gitlab-enabled-mcp-server-tools header is absent' do
      it 'returns all available tools unfiltered' do
        post_list_tools

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_issue', 'create_issue', 'search', 'get_merge_request')
      end
    end

    context 'when x-gitlab-mcp-server-tool-name-prefix header is present' do
      it 'prefixes all tools with header value' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Mcp-Server-Tool-Name-Prefix' => 'test_' }

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to all start_with('test_')
      end

      it 'truncates prefix to 32 chars' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Mcp-Server-Tool-Name-Prefix' => 'a' * 33 }

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include("#{'a' * 32}search")
      end
    end

    context 'when a tool has no icons' do
      before do
        allow_any_instance_of(::Mcp::Tools::GetServerVersionService).to receive(:icons).and_return([]) # rubocop: disable RSpec/AnyInstanceOf -- tools are initialized on class definition time
      end

      it 'does not include icons key for that tool' do
        post_list_tools

        tools = json_response['result']['tools']
        version_tool = tools.find { |tool| tool['name'] == 'get_mcp_server_version' }

        expect(version_tool).not_to have_key('icons')
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
