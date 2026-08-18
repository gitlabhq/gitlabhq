# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Search::SearchService, feature_category: :mcp_server do
  let(:mock_tool_global) { instance_double(Mcp::Tools::Base::ApiTool, name: :gitlab_search_in_instance) }
  let(:mock_tool_group) { instance_double(Mcp::Tools::Base::ApiTool, name: :gitlab_search_in_group) }
  let(:mock_tool_project) { instance_double(Mcp::Tools::Base::ApiTool, name: :gitlab_search_in_project) }
  let(:tools) { [mock_tool_global, mock_tool_group, mock_tool_project] }
  let(:service) { described_class.new(tools: tools) }

  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('search')
    end
  end

  describe '.tool_aliases' do
    it 'returns deprecated tool names' do
      expect(described_class.tool_aliases).to eq(['gitlab_search'])
    end
  end

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq("" \
        "Search across GitLab with automatic selection of the best available search method.\n\n" \
        "**Capabilities:** basic (keywords, file filters)\n\n" \
        "**Syntax Examples:**\n- Basic: \"bug fix\", \"filename:*.rb\", \"extension:js\"")
    end
  end

  describe '#input_schema' do
    let(:schema) { service.input_schema }

    it 'exposes the expected input schema', unless: Gitlab.ee? do
      expect(schema).to match(
        type: 'object',
        additionalProperties: false,
        required: %w[scope search],
        properties: {
          scope: {
            type: 'string',
            description: a_string_including(
              'GitLab instance: projects, work_items, merge_requests, milestones, users, snippet_titles',
              'Group: projects, work_items, merge_requests, milestones, users',
              'Project: blobs, work_items, merge_requests, wiki_blobs, commits, notes, milestones, users',
              'Use "work_items" to search for issues, tasks, epics, and other work items'
            )
          },
          search: { type: 'string', description: 'The term to search for' },
          group_id: { type: 'string', description: a_string_including('within a group') },
          project_id: { type: 'string', description: a_string_including('within a project') },
          state: {
            type: 'string',
            description: a_string_including(
              'Work items:',
              'Only applies to work_items and merge_requests scopes.'
            )
          },
          confidential: { type: 'boolean', description: a_string_including('confidentiality') },
          order_by: { type: 'string', description: a_string_including('created_at') },
          sort: { type: 'string', description: a_string_including('asc, desc') },
          per_page: { type: 'integer', minimum: 1, description: a_string_including('per page') },
          page: { type: 'integer', minimum: 1, description: a_string_including('Page number') }
        }
      )
    end
  end

  describe '#execute' do
    let(:request) { nil }
    let(:params) { { arguments: arguments } }
    let(:mock_response) { { content: [{ type: 'text', text: 'Success' }], isError: false } }

    context 'with global search arguments' do
      let(:arguments) { { scope: 'issues', search: 'test query' } }

      it 'selects the global search tool' do
        expect(mock_tool_global).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result).to eq(mock_response)
      end
    end

    context 'with group search arguments' do
      let(:arguments) { { scope: 'issues', search: 'test query', group_id: 'test-group' } }
      let(:transformed_params) { { arguments: arguments.merge(id: 'test-group') } }

      it 'selects the group search tool and transforms arguments' do
        expect(mock_tool_group).to receive(:execute).with(request: request,
          params: transformed_params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result).to eq(mock_response)
      end
    end

    context 'with project search arguments' do
      let(:arguments) { { scope: 'issues', search: 'test query', project_id: 'test-project' } }
      let(:transformed_params) { { arguments: arguments.merge(id: 'test-project') } }

      it 'selects the project search tool and transforms arguments' do
        expect(mock_tool_project).to receive(:execute).with(request: request,
          params: transformed_params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result).to eq(mock_response)
      end
    end

    context 'with both group_id and project_id' do
      let(:arguments) { { scope: 'issues', search: 'test query', group_id: 'test-group', project_id: 'test-project' } }
      let(:transformed_params) { { arguments: arguments.merge(id: 'test-project') } }

      it 'prioritizes project search over group search' do
        expect(mock_tool_project).to receive(:execute).with(request: request,
          params: transformed_params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result).to eq(mock_response)
      end
    end

    context 'when tool is not found' do
      let(:arguments) { { scope: 'issues', search: 'test query' } }
      let(:service_with_empty_tools) { described_class.new(tools: []) }

      it 'returns error response' do
        result = service_with_empty_tools.execute(request: request, params: params)

        expect(result[:isError]).to be true

        expected_text = "Tool execution failed: Tool 'search' not found."
        expect(result[:content].first[:text]).to eq(expected_text)
      end
    end

    context 'when validation fails' do
      let(:arguments) { { scope: 'issues' } }

      it 'returns validation error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error:')
      end
    end

    context 'when tool execution fails' do
      let(:arguments) { { scope: 'issues', search: 'test query' } }

      before do
        allow(mock_tool_global).to receive(:execute).and_raise(StandardError, 'Tool failed')
      end

      it 'returns execution error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Tool execution failed: Tool failed')
      end
    end

    context 'when search_level is not supported' do
      let(:arguments) { { scope: 'issues', search: 'test query' } }

      it 'raises an ArgumentError' do
        mock_level = instance_double(Search::Level, as_sym: :unsupported_value)
        allow(service).to receive(:search_level).and_return(mock_level)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Validation error: Unsupported search level: unsupported_value')
      end
    end
  end
end
