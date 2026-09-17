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
      post api('/mcp', user, oauth_access_token: access_token),
        params: params,
        headers: { 'X-Gitlab-Enabled-Mcp-Server-Toolsets' => 'all' }

      expected_annotations = {
        # write, non-destructive
        'add_branch' => { 'readOnlyHint' => false, 'destructiveHint' => false, 'toolset' => 'repository' },
        'save_merge_request' => { 'readOnlyHint' => false, 'destructiveHint' => false,
                                  'toolset' => 'merge_requests' },
        'fork_repository' => { 'readOnlyHint' => false, 'destructiveHint' => false, 'toolset' => 'repository' },
        'link_work_items' => { 'readOnlyHint' => false, 'destructiveHint' => false, 'toolset' => 'work_items' },
        'save_merge_request_review' => { 'readOnlyHint' => false, 'destructiveHint' => false,
                                         'toolset' => 'merge_requests' },
        'save_note' => { 'readOnlyHint' => false, 'destructiveHint' => false, 'toolset' => 'core' },
        'save_work_item' => { 'readOnlyHint' => false, 'destructiveHint' => false, 'toolset' => 'work_items' },
        # write, destructive
        'accept_merge_request' => { 'readOnlyHint' => false, 'destructiveHint' => true,
                                    'toolset' => 'merge_requests' },
        'add_commit' => { 'readOnlyHint' => false, 'destructiveHint' => true, 'toolset' => 'repository' },
        'manage_pipeline' => { 'readOnlyHint' => false, 'destructiveHint' => true, 'toolset' => 'ci' },
        'save_pipeline' => { 'readOnlyHint' => false, 'destructiveHint' => true, 'toolset' => 'ci' },
        # read-only
        'get_artifact_file' => { 'readOnlyHint' => true, 'toolset' => 'ci' },
        'get_commit' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'get_job' => { 'readOnlyHint' => true, 'toolset' => 'ci' },
        'get_mcp_server_version' => { 'readOnlyHint' => true, 'toolset' => 'meta' },
        'get_merge_request' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'get_merge_request_commits' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'get_merge_request_conflicts' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'get_merge_request_diffs' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'get_merge_request_notes' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'get_merge_request_pipelines' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'get_pipeline' => { 'readOnlyHint' => true, 'toolset' => 'ci' },
        'get_pipeline_jobs' => { 'readOnlyHint' => true, 'toolset' => 'ci' },
        'get_project' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'get_repository_file' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'get_saved_view_work_items' => { 'readOnlyHint' => true, 'toolset' => 'work_items' },
        'get_user' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'get_work_item' => { 'readOnlyHint' => true, 'toolset' => 'work_items' },
        'get_work_item_types' => { 'readOnlyHint' => true, 'toolset' => 'work_items' },
        'list_branches' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'list_commits' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'list_groups' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'list_merge_requests' => { 'readOnlyHint' => true, 'toolset' => 'merge_requests' },
        'list_project_members' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'list_pipelines' => { 'readOnlyHint' => true, 'toolset' => 'ci' },
        'list_projects' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'list_releases' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'list_repository_tree' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'list_tags' => { 'readOnlyHint' => true, 'toolset' => 'repository' },
        'list_work_items' => { 'readOnlyHint' => true, 'toolset' => 'work_items' },
        'search' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'search_labels' => { 'readOnlyHint' => true, 'toolset' => 'core' },
        'list_wiki_pages' => { 'readOnlyHint' => true, 'toolset' => 'wikis' }
      }

      actual_annotations = json_response['result']['tools'].to_h { |tool| [tool['name'], tool['annotations']] }

      expect(actual_annotations.keys).to match_array(expected_annotations.keys)
      expect(actual_annotations).to eq(expected_annotations)
    end

    it 'surfaces every MCP-enabled API endpoint as a tool', :aggregate_failures do
      post_list_tools

      api_tool_names = ::API::API.routes.filter_map do |route|
        settings = route.app.route_setting(:mcp)
        next if settings.blank? || settings[:aggregators].present? || settings[:unlisted].present?

        settings[:tool_name].to_s
      end.uniq

      surfaced_names = json_response['result']['tools'].pluck('name')

      expect(api_tool_names).not_to be_empty, 'No MCP-enabled API routes were discovered'
      expect(surfaced_names).to include(*api_tool_names)
    end

    it 'only lists save_merge_request params that its routes actually declare', :aggregate_failures do
      save_mr_routes = ::API::API.routes.select do |route|
        route.app.route_setting(:mcp)&.dig(:aggregators)&.include?(::Mcp::Tools::MergeRequests::SaveMergeRequestService)
      end

      expect(save_mr_routes.size).to eq(2), 'Expected save_merge_request to aggregate the create and update routes'

      save_mr_routes.each do |route|
        settings = route.app.route_setting(:mcp)
        stale = settings[:params].map(&:to_s) - route.params.keys.map(&:to_s)

        expect(stale).to be_empty,
          "MCP tool '#{settings[:tool_name]}' lists params not declared on its route: #{stale.inspect}. " \
            "Update the tool's mcp params list to match the route params."
      end
    end

    it 'advertises the list_branches params', :aggregate_failures do
      post_list_tools

      schema = json_response['result']['tools'].find { |tool| tool['name'] == 'list_branches' }['inputSchema']

      expect(schema['properties'].keys).to match_array(%w[id search page per_page])
      expect(schema['required']).to contain_exactly('id')
    end

    it 'ensures every MCP-enabled route has a matching allow_mcp_access declaration',
      :eager_load, :aggregate_failures do
      method_to_access = {
        'GET' => :get?,
        'HEAD' => :head?,
        'POST' => :post?,
        'PUT' => :put?,
        'PATCH' => :patch?,
        'DELETE' => :delete?
      }.freeze

      ::API::API.routes.each do |route|
        settings = route.app.route_setting(:mcp)
        next if settings.blank?

        http_method = route.request_method
        next unless method_to_access.key?(http_method)

        api_class = route.app.options[:for]
        mcp_scopes = api_class.allowed_scopes.select { |s| s.name == :mcp }

        request_double = instance_double(ActionDispatch::Request)
        method_to_access.each_value { |m| allow(request_double).to receive(m).and_return(false) }
        allow(request_double).to receive(method_to_access[http_method]).and_return(true)

        matched = mcp_scopes.any? { |scope| scope.sufficient?([:mcp], request_double) }

        expect(matched).to be(true),
          "#{api_class} registers MCP tool '#{settings[:tool_name]}' on #{http_method} " \
            "but has no allow_mcp_access_* declaration that permits #{http_method} requests. " \
            "Add the appropriate allow_mcp_access_* call for the HTTP method."
      end
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

    it 'derives enum for list_pipelines status, source, order_by, and sort from their Grape values: constraint',
      :aggregate_failures do
      post_list_tools

      list_pipelines = json_response['result']['tools'].find { |tool| tool['name'] == 'list_pipelines' }
      properties = list_pipelines.dig('inputSchema', 'properties')

      expect(properties.dig('status', 'enum')).to eq(::Ci::HasStatus::AVAILABLE_STATUSES)
      expect(properties.dig('source', 'enum')).to eq(::Ci::Pipeline.sources.keys)
      expect(properties.dig('order_by', 'enum')).to eq(::Ci::PipelinesFinder::ALLOWED_INDEXED_COLUMNS)
      expect(properties.dig('sort', 'enum')).to eq(%w[asc desc])
      expect(properties.dig('created_after', 'type')).to eq('string')
      expect(properties.dig('created_before', 'type')).to eq('string')
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

        composition_keys = %w[oneOf anyOf allOf $ref]
        next if composition_keys.any? { |k| schema.key?(k) }

        expect(schema).to have_key('additionalProperties'),
          "Tool '#{name}' inputSchema must set additionalProperties: #{schema.inspect}"
        expect(schema['additionalProperties']).to be_in([true, false]),
          "Tool '#{name}' inputSchema additionalProperties must be a boolean: #{schema.inspect}"
      end
    end

    it 'includes icon for all tools' do
      post_list_tools

      tools = json_response['result']['tools']

      expect(tools).not_to be_empty, 'No tools returned'

      expected_icon = Mcp::Tools::Base::IconConfig.gitlab_icons.first.stringify_keys

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

    context 'with tools retired from the catalog' do
      it 'does not advertise retired tools but keeps them callable' do
        post_list_tools

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).not_to include('create_issue', 'get_workitem_notes', 'get_issue')
        manager = ::Mcp::Tools::Manager.new
        expect(manager.get_tool(name: 'create_issue')).to be_present
        expect(manager.get_tool(name: 'get_workitem_notes')).to be_present
        expect(manager.get_tool(name: 'get_issue')).to be_present
      end
    end

    context 'when a tool is unlisted' do
      let(:manager) do
        ::Mcp::Tools::Manager.new.tap do |m|
          allow(m.list_tools['get_mcp_server_version']).to receive(:unlisted?).and_return(true)
        end
      end

      before do
        handler = ::API::Mcp::Handlers::ListTools.new(manager)
        allow(::API::Mcp::Handlers::ListTools).to receive(:new).and_return(handler)
      end

      it 'is excluded from the list' do
        post_list_tools

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).not_to include('get_mcp_server_version')
      end
    end

    context 'when x-gitlab-enabled-mcp-server-tools header is present' do
      # The filter only needs some advertised tools, not specific ones. Deriving
      # the fixtures from the live catalog keeps tool retirements from churning
      # these examples.
      let(:advertised_tools) do
        post_list_tools
        json_response['result']['tools'].pluck('name')
      end

      def post_list_tools_with_allowed(allowed_tools)
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Enabled-Mcp-Server-Tools' => allowed_tools }
      end

      it 'returns only the tools listed in the header' do
        allowed = advertised_tools.first(2)
        post_list_tools_with_allowed(allowed.join(','))

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to match_array(allowed)
      end

      it 'excludes tools not in the allowed list' do
        allowed, *rest = advertised_tools
        post_list_tools_with_allowed(allowed)

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).not_to include(*rest)
      end

      it 'handles a single tool correctly' do
        allowed = advertised_tools.last
        post_list_tools_with_allowed(allowed)

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to contain_exactly(allowed)
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
          expect(tool_names).to match_array(advertised_tools)
        end
      end
    end

    context 'when x-gitlab-enabled-mcp-server-tools header is absent' do
      it 'returns all available tools unfiltered' do
        post_list_tools

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_commit', 'get_pipeline', 'search', 'get_merge_request')
      end
    end

    context 'when x-gitlab-enabled-mcp-server-toolsets header is present' do
      def post_list_tools_with_toolsets(toolsets)
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Enabled-Mcp-Server-Toolsets' => toolsets }
      end

      it 'returns only tools from the requested toolsets plus ALWAYS_ON' do
        post_list_tools_with_toolsets('ci')

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_pipeline', 'get_mcp_server_version')
        expect(tool_names).not_to include('get_merge_request', 'get_work_item')
      end

      it 'accepts multiple toolsets' do
        post_list_tools_with_toolsets('ci,merge_requests')

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_pipeline', 'get_merge_request', 'get_mcp_server_version')
        expect(tool_names).not_to include('get_work_item')
      end

      it 'returns 400 for invalid toolset names' do
        post_list_tools_with_toolsets('ci,bogus')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response.dig('error', 'data', 'params')).to include('Unknown toolsets: bogus')
      end

      it 'returns 400 when all toolsets are invalid' do
        post_list_tools_with_toolsets('bogus')

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 for an invalid toolset name alongside the "all" pseudo-value' do
        post_list_tools_with_toolsets('all,bogus')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response.dig('error', 'data', 'params')).to include('Unknown toolsets: bogus')
      end

      it 'falls back to defaults when header contains only commas' do
        post_list_tools_with_toolsets(' , , ')

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_pipeline', 'get_mcp_server_version')
        expect(tool_names).not_to include('list_wiki_pages')
      end

      it 'falls back to defaults when the tools header contains only commas' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Enabled-Mcp-Server-Tools' => ' , , ' }

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_pipeline', 'get_mcp_server_version')
        expect(tool_names).not_to include('list_wiki_pages')
      end

      context 'with the "all" pseudo-value' do
        it 'returns tools from every toolset including opt-in', unless: Gitlab.ee? do
          post_list_tools_with_toolsets('all')

          tool_names = json_response['result']['tools'].pluck('name')
          expect(tool_names).to include('get_pipeline', 'get_merge_request', 'get_work_item',
            'get_mcp_server_version', 'list_wiki_pages')
        end
      end

      context 'when combined with x-gitlab-enabled-mcp-server-tools' do
        it 'returns the union of both filters' do
          post api('/mcp', user, oauth_access_token: access_token),
            params: params,
            headers: {
              'X-Gitlab-Enabled-Mcp-Server-Toolsets' => 'ci',
              'X-Gitlab-Enabled-Mcp-Server-Tools' => 'get_work_item'
            }

          tool_names = json_response['result']['tools'].pluck('name')
          expect(tool_names).to include('get_pipeline', 'get_work_item', 'get_mcp_server_version')
          expect(tool_names).not_to include('get_merge_request')
        end
      end
    end

    context 'when no toolset header is present' do
      it 'returns only DEFAULT + ALWAYS_ON toolset tools' do
        post_list_tools

        tool_names = json_response['result']['tools'].pluck('name')
        default_toolsets = Mcp::Tools::Toolsets::DEFAULT + Mcp::Tools::Toolsets::ALWAYS_ON
        manager = Mcp::Tools::Manager.new

        manager.tools.each do |name, tool|
          next if tool.unlisted?

          if default_toolsets.include?(tool.toolset)
            expect(tool_names).to include(name), "Expected DEFAULT tool '#{name}' to be present"
          else
            expect(tool_names).not_to include(name),
              "Expected OPT_IN tool '#{name}' (toolset :#{tool.toolset}) to be excluded"
          end
        end
      end
    end

    context 'when mcp_toolsets feature flag is disabled' do
      before do
        stub_feature_flags(mcp_toolsets: false)
      end

      it 'ignores the toolsets header and returns all tools' do
        post api('/mcp', user, oauth_access_token: access_token),
          params: params,
          headers: { 'X-Gitlab-Enabled-Mcp-Server-Toolsets' => 'ci' }

        tool_names = json_response['result']['tools'].pluck('name')
        expect(tool_names).to include('get_merge_request', 'get_work_item', 'get_pipeline')
      end

      it 'omits the toolset annotation', :aggregate_failures do
        post_list_tools

        annotations = json_response['result']['tools'].filter_map { |tool| tool['annotations'] }

        expect(annotations).to be_present
        expect(annotations.flat_map(&:keys)).not_to include('toolset')
      end
    end

    it 'includes toolset annotation on every tool' do
      post_list_tools

      tools = json_response['result']['tools']
      valid_toolsets = Mcp::Tools::Toolsets::ALL.map(&:to_s)

      tools.each do |tool|
        expect(tool.dig('annotations', 'toolset')).to be_in(valid_toolsets),
          "Tool '#{tool['name']}' missing or invalid toolset annotation"
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
