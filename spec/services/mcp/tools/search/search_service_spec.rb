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
    it 'locks the full input schema for version 0.1.0', unless: Gitlab.ee? do
      expect(service.input_schema).to eq({
        type: 'object',
        properties: {
          scope: {
            type: 'string',
            description: 'Specify the type of content to search for. Available content types vary by search ' \
              "context:\n" \
              "\n" \
              '- GitLab instance: projects, groups, work_items, merge_requests, milestones, users, ' \
              "snippet_titles\n" \
              "- Group: projects, groups, work_items, merge_requests, milestones, users\n" \
              '- Project: blobs, work_items, merge_requests, wiki_blobs, commits, notes, milestones, ' \
              "users\n" \
              "\n" \
              "Examples:\n" \
              "- Use \"work_items\" to search for issues, tasks, epics, and other work items\n" \
              "- Use \"merge_requests\" to search for merge requests\n" \
              "- Use \"blobs\" to search code files\n" \
              "- Use \"notes\" to search comments across different content\n" \
              '- Use "commits" to search commit messages'
          },
          search: {
            type: 'string',
            description: 'The term to search for'
          },
          group_id: {
            type: 'string',
            description: 'Provide to search within a group. The ID or full path of the group'
          },
          project_id: {
            type: 'string',
            description: 'Provide to search within a project. The ID or full path of the project'
          },
          state: {
            type: 'string',
            description: "Filter results by state. Available states:\n" \
              "- Work items: opened, closed\n" \
              "- Merge requests: opened, closed, merged, locked\n" \
              "\n" \
              'Only applies to work_items and merge_requests scopes.'
          },
          confidential: {
            type: 'boolean',
            description: 'Filter results by confidentiality. Available for work_items scope; other scopes are ' \
              'ignored.'
          },
          order_by: {
            type: 'string',
            description: "Specify how to order search results.\n" \
              "- Allowed values: created_at only\n" \
              "- Default behavior:\n  " \
              "* Basic search: sorted by created_at descending\n  " \
              '* Advanced search: sorted by relevance'
          },
          sort: {
            type: 'string',
            description: "Specify the sort direction for results. Works with order_by parameter\n" \
              "- Allowed values: asc, desc\n" \
              '- Default: desc'
          },
          per_page: {
            type: 'integer',
            description: 'Number of items to list per page. (default: 20)',
            minimum: 1
          },
          page: {
            type: 'integer',
            description: 'Page number to retrieve. (default: 1)',
            minimum: 1
          }
        },
        required: %w[scope search],
        additionalProperties: false
      })
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

        expected_text = "Tool execution failed: search is not available on this GitLab instance " \
          "due to a server configuration problem."
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
