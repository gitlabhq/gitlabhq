# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::AggregatedService, feature_category: :mcp_server do
  let(:service_name) { 'test_aggregated_tool' }
  let(:mock_tool) { instance_double(Mcp::Tools::ApiTool, name: :gitlab_search_in_instance) }
  let(:mock_tool_2) { instance_double(Mcp::Tools::ApiTool, name: :gitlab_search_in_group) }
  let(:tools) { [mock_tool, mock_tool_2] }

  describe '#initialize' do
    let(:test_service_class) do
      Class.new(described_class) do
        register_version '0.1.0', {
          description: 'test klass',
          input_schema: {
            type: 'object',
            properties: {}
          }
        }

        def self.tool_name
          'test_aggregated_tool'
        end
      end
    end

    it 'initializes with tools and sets name from tool_name' do
      service = test_service_class.new(tools: tools)

      expect(service.instance_variable_get(:@tools)).to eq(tools)
      expect(service.instance_variable_get(:@name)).to eq('test_aggregated_tool')
    end
  end

  describe '#execute' do
    let(:arguments) { { scope: 'issues', search: 'test' } }
    let(:params) { { arguments: arguments } }

    context 'when version-specific method exists' do
      let(:service_with_version_method_class) do
        Class.new(described_class) do
          register_version '1.0.0', {
            description: 'Test aggregated tool',
            input_schema: {
              type: 'object',
              properties: {
                scope: { type: 'string' },
                search: { type: 'string' }
              },
              required: %w[scope search]
            }
          }

          register_version '1.5.0', {
            description: 'second version of test tool',
            input_schema: {
              type: 'object',
              properties: {
                scope: { type: 'string' },
                search: { type: 'string' }
              },
              required: %w[scope search]
            }
          }

          register_version '2.0.0', {
            description: 'major version with breaking changes',
            input_schema: {
              type: 'object',
              properties: {
                scope: { type: 'string' },
                search: { type: 'string' },
                search_type: { type: 'string' }
              },
              required: %w[scope search search_type]
            }
          }

          def self.tool_name
            'test_aggregated_tool'
          end

          private

          def perform_1_0_0(_args)
            tool = tools.first

            tool.execute(request:, params:)
          end

          def perform_2_0_0(_args)
            tool = tools.second
            params[:arguments][:another] = 1

            tool.execute(request:, params:)
          end
        end
      end

      it 'calls the correct version method' do
        service = service_with_version_method_class.new(tools: tools, version: '1.0.0')

        mock_response_1 = { content: [{ type: 'text', text: 'Success' }], isError: false }
        expect(mock_tool).to receive(:execute).with(request: nil, params: params).and_return(mock_response_1)

        result_1 = service.execute(request: nil, params: params)
        expect(result_1).to eq(mock_response_1)
      end

      it 'handles different versions correctly' do
        service_v1 = service_with_version_method_class.new(tools: tools, version: '1.0.0')
        service_v2 = service_with_version_method_class.new(tools: tools, version: '2.0.0')

        mock_response_1 = { content: [{ type: 'text', text: 'Success one' }], isError: false }
        mock_response_2 = { content: [{ type: 'text', text: 'Success two' }], isError: false }

        params_2 = params
        params_2[:arguments][:search_type] = 'basic'

        expect(mock_tool).to receive(:execute).with(request: nil, params: params).and_return(mock_response_1)
        expect(mock_tool_2).to receive(:execute).with(request: nil, params: params_2).and_return(mock_response_2)

        result_1 = service_v1.execute(request: nil, params: params)
        result_2 = service_v2.execute(request: nil, params: params_2)

        expect(result_1).to eq(mock_response_1)
        expect(result_2).to eq(mock_response_2)
      end
    end

    context 'when version-specific method does not exist' do
      let(:service_without_method_class) do
        Class.new(described_class) do
          register_version '3.0.0', {
            description: 'Version without implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def self.tool_name
            'test_aggregated_tool'
          end

          private

          def select_tool(_args)
            tools.first
          end

          def transform_arguments(args)
            args
          end
        end
      end

      it 'calls perform_default' do
        mock_response_1 = { content: [{ type: 'text', text: 'Success default' }], isError: false }
        expect(mock_tool).to receive(:execute).with(request: nil, params: params).and_return(mock_response_1)

        service = service_without_method_class.new(tools: tools, version: '3.0.0')
        result = service.execute(request: nil, params: params)

        expect(result[:content]).to match_array(mock_response_1[:content])
      end
    end

    context 'when aggregated tool performs without error' do
      let(:service_class) do
        Class.new(described_class) do
          register_version '3.0.0', {
            description: 'Version without implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def self.tool_name
            'test_aggregated_tool'
          end

          def select_tool(*)
            tools.first
          end

          def transform_arguments(args)
            args.merge(id: 'transformed')
          end
        end
      end

      let(:transformed_arguments) { arguments.merge(id: 'transformed') }
      let(:transformed_params) { { arguments: transformed_arguments } }
      let(:mock_response) { { content: [{ type: 'text', text: 'Success' }], isError: false } }

      it 'delegates to selected tool with transformed arguments' do
        expect(mock_tool).to receive(:execute).with(request: nil, params: transformed_params).and_return(mock_response)

        service = service_class.new(tools: tools)
        result = service.execute(request: nil, params: params)
        expect(result).to eq(mock_response)
      end
    end

    context 'when aggregated tool cannot find tool' do
      let(:arguments) { { scope: 'issues', search: 'test' } }
      let(:params) { { arguments: arguments } }

      let(:test_service_class) do
        Class.new(described_class) do
          register_version '1.5.0', {
            description: 'Test aggregated tool',
            input_schema: {
              type: 'object',
              properties: {
                scope: { type: 'string' },
                search: { type: 'string' }
              },
              required: %w[scope search]
            }
          }

          def self.tool_name
            'test_aggregated_tool'
          end

          private

          def select_tool(_args)
            nil
          end

          def transform_arguments(args)
            args
          end
        end
      end

      let(:service) { test_service_class.new(tools: tools) }

      it 'returns error response when tool not found' do
        result = service.execute(request: nil, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text])
          .to eq("Tool execution failed: Tool 'test_aggregated_tool' not found.")
      end
    end

    context 'when aggregated tool is called with invalid arguments' do
      let(:arguments) { { scope: 'issues' } }
      let(:params) { { arguments: arguments } }

      let(:test_service_class) do
        Class.new(described_class) do
          register_version '1.5.0', {
            description: 'Test aggregated tool',
            input_schema: {
              type: 'object',
              properties: {
                scope: { type: 'string' },
                search: { type: 'string' }
              },
              required: %w[scope search]
            }
          }

          def self.tool_name
            'test_aggregated_tool'
          end

          private

          def select_tool(_args)
            tools.first
          end

          def transform_arguments(args)
            args
          end
        end
      end

      let(:service) { test_service_class.new(tools: tools) }

      it 'returns validation error response' do
        result = service.execute(request: nil, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error:')
        expect(result[:content].first[:text]).to include('search is missing')
      end
    end

    context 'when delegated tool execution fails' do
      let(:test_service_class) do
        Class.new(described_class) do
          register_version '3.0.0', {
            description: 'Version without implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def self.tool_name
            'test_aggregated_tool'
          end

          def select_tool(_args)
            tools.first
          end

          def transform_arguments(args)
            args
          end
        end
      end

      it 'returns error response when delegated tool fails' do
        expect(mock_tool).to receive(:execute).and_raise(StandardError, 'Tool execution failed')

        service = test_service_class.new(tools: tools)
        result = service.execute(request: nil, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Tool execution failed: Tool execution failed')
      end
    end
  end

  describe 'abstract methods' do
    describe '.tool_name' do
      it 'raises NoMethodError when not implemented' do
        expect { described_class.tool_name }
          .to raise_error(NoMethodError, /tool_name should be implemented in a subclass/)
      end
    end

    describe '#select_tool' do
      let(:test_service_class) do
        Class.new(described_class) do
          register_version '1.0.0', {
            description: 'Test tool',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def self.tool_name
            'test_tool'
          end

          def transform_arguments(args)
            args
          end
        end
      end

      it 'raises NoMethodError when not implemented in subclass' do
        service = test_service_class.new(tools: tools)
        params = { arguments: {} }

        result = service.execute(request: nil, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('select_tool should be implemented in a subclass')
      end
    end

    describe '#transform_arguments' do
      let(:test_service_class) do
        Class.new(described_class) do
          register_version '1.0.0', {
            description: 'Test tool',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def self.tool_name
            'test_tool'
          end

          def select_tool(_args)
            tools.first
          end
        end
      end

      it 'raises NoMethodError when not implemented in subclass' do
        service = test_service_class.new(tools: tools)
        params = { arguments: {} }

        result = service.execute(request: nil, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('transform_arguments should be implemented in a subclass')
      end
    end
  end
end
