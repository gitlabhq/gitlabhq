# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GitlabSearchService, feature_category: :mcp_server do
  let(:mock_tool_global) { instance_double(Mcp::Tools::ApiTool, name: :gitlab_search_in_instance) }
  let(:mock_tool_group) { instance_double(Mcp::Tools::ApiTool, name: :gitlab_search_in_group) }
  let(:mock_tool_project) { instance_double(Mcp::Tools::ApiTool, name: :gitlab_search_in_project) }
  let(:tools) { [mock_tool_global, mock_tool_group, mock_tool_project] }
  let(:service) { described_class.new(tools: tools) }

  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('gitlab_search')
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

    it 'returns a valid schema structure' do
      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[scope search])
      expect(schema[:additionalProperties]).to be false
    end

    it 'includes all expected properties' do
      properties = schema[:properties]

      expect(properties).to have_key(:scope)
      expect(properties).to have_key(:search)
      expect(properties).to have_key(:group_id)
      expect(properties).to have_key(:project_id)
      expect(properties).to have_key(:state)
      expect(properties).to have_key(:confidential)
      expect(properties).to have_key(:fields)
      expect(properties).to have_key(:order_by)
      expect(properties).to have_key(:sort)
      expect(properties).to have_key(:per_page)
      expect(properties).to have_key(:page)
    end

    it 'has correct property types' do
      properties = schema[:properties]

      expect(properties[:scope][:type]).to eq('string')
      expect(properties[:search][:type]).to eq('string')
      expect(properties[:group_id][:type]).to eq('string')
      expect(properties[:project_id][:type]).to eq('string')
      expect(properties[:state][:type]).to eq('string')
      expect(properties[:confidential][:type]).to eq('boolean')
      expect(properties[:fields][:type]).to eq('array')
      expect(properties[:order_by][:type]).to eq('string')
      expect(properties[:sort][:type]).to eq('string')
      expect(properties[:per_page][:type]).to eq('integer')
      expect(properties[:page][:type]).to eq('integer')
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

        expected_text = "Tool execution failed: Tool 'gitlab_search' not found."
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
