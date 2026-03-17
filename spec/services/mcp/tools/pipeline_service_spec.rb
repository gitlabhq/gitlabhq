# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::PipelineService, feature_category: :mcp_server do
  let(:create_tool) { instance_double(Mcp::Tools::ApiTool, name: :create_pipeline) }
  let(:update_tool) { instance_double(Mcp::Tools::ApiTool, name: :update_pipeline) }
  let(:retry_tool) { instance_double(Mcp::Tools::ApiTool, name: :retry_pipeline) }
  let(:cancel_tool) { instance_double(Mcp::Tools::ApiTool, name: :cancel_pipeline) }
  let(:delete_tool) { instance_double(Mcp::Tools::ApiTool, name: :delete_pipeline) }
  let(:list_tool) { instance_double(Mcp::Tools::ApiTool, name: :list_pipelines) }
  let(:tools) { [create_tool, update_tool, retry_tool, cancel_tool, delete_tool, list_tool] }
  let(:service) { described_class.new(tools: tools) }

  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('manage_pipeline')
    end
  end

  describe '#description' do
    it 'returns the correct description' do
      description = service.description

      %w[List Create Update Retry Cancel Delete].each do |action|
        expect(description).to include(action)
      end
    end
  end

  describe '#annotations' do
    it 'returns correct annotations' do
      expect(service.annotations).to eq({
        readOnlyHint: false,
        destructiveHint: true
      })
    end
  end

  describe '#input_schema' do
    let(:schema) { service.input_schema }

    it 'returns a valid schema structure' do
      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(['id'])
      expect(schema[:additionalProperties]).to be false
    end

    it 'includes all expected properties' do
      properties = schema[:properties]

      expect(properties).to include(:id, :list, :ref, :pipeline_id, :retry, :cancel, :name, :variables, :inputs)
    end

    it 'has correct property types' do
      properties = schema[:properties]

      expect(properties[:id][:type]).to eq('string')
      expect(properties[:list][:type]).to eq('boolean')
      expect(properties[:ref][:type]).to eq('string')
      expect(properties[:pipeline_id][:type]).to eq('integer')
      expect(properties[:retry][:type]).to eq('boolean')
      expect(properties[:cancel][:type]).to eq('boolean')
      expect(properties[:inputs][:type]).to eq('object')
    end
  end

  describe '#execute' do
    let(:request) { nil }
    let(:params) { { arguments: arguments } }
    let(:mock_response) do
      {
        content: [{ type: 'text', text: '{"id":1,"status":"created"}' }],
        structuredContent: { id: 1, status: 'created' },
        isError: false
      }
    end

    context 'with create pipeline arguments' do
      let(:arguments) { { id: 'project-1', ref: 'main' } }

      it 'selects the create_pipeline tool' do
        expect(create_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'create',
          tool: 'create_pipeline',
          aggregator: 'manage_pipeline'
        })
        expect(result[:content].first[:text]).to include('Pipeline created successfully via manage_pipeline')
      end
    end

    context 'with list pipeline arguments' do
      let(:arguments) { { id: 'project-1', list: true } }

      it 'selects the list_pipelines tool' do
        expect(list_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'list',
          tool: 'list_pipelines',
          aggregator: 'manage_pipeline'
        })
        expect(result[:content].first[:text]).to include('Pipeline listed successfully via manage_pipeline')
      end
    end

    context 'with retry pipeline arguments' do
      let(:arguments) { { id: 'project-1', pipeline_id: 123, retry: true } }

      it 'selects the retry_pipeline tool' do
        expect(retry_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'retry',
          tool: 'retry_pipeline',
          aggregator: 'manage_pipeline'
        })
        expect(result[:content].first[:text]).to include('Pipeline retried successfully')
      end
    end

    context 'with cancel pipeline arguments' do
      let(:arguments) { { id: 'project-1', pipeline_id: 123, cancel: true } }

      it 'selects the cancel_pipeline tool and enhances response with operation metadata' do
        expect(cancel_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'cancel',
          tool: 'cancel_pipeline',
          aggregator: 'manage_pipeline'
        })
        expect(result[:content].first[:text]).to include('Pipeline canceled successfully via manage_pipeline')
      end
    end

    context 'with update pipeline arguments' do
      let(:arguments) { { id: 'project-1', pipeline_id: 123, name: 'New Pipeline Name' } }

      it 'selects the update_pipeline tool' do
        expect(update_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'update',
          tool: 'update_pipeline',
          aggregator: 'manage_pipeline'
        })
        expect(result[:content].first[:text]).to include('Pipeline updated successfully via manage_pipeline')
      end
    end

    context 'when tool is not found' do
      let(:arguments) { { id: 'project-1', ref: 'main' } }
      let(:service_with_empty_tools) { described_class.new(tools: []) }

      it 'returns error response' do
        result = service_with_empty_tools.execute(request: request, params: params)

        expect(result[:isError]).to be true

        expected_text = "Tool execution failed: Tool 'manage_pipeline' not found."
        expect(result[:content].first[:text]).to eq(expected_text)
      end
    end

    context 'when validation fails' do
      let(:arguments) { { id: 'project-1' } }

      it 'returns validation error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error:')
      end
    end

    context 'when tool execution fails' do
      let(:arguments) { { id: 'project-1', ref: 'main' } }

      before do
        allow(create_tool).to receive(:execute).and_raise(StandardError, 'Pipeline creation failed')
      end

      it 'returns execution error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Tool execution failed: Pipeline creation failed')
      end
    end

    context 'with pipeline_id alone (delete scenario)' do
      let(:arguments) { { id: 'project-1', pipeline_id: 99 } }

      it 'selects the delete_pipeline tool' do
        expect(delete_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'delete',
          tool: 'delete_pipeline',
          aggregator: 'manage_pipeline'
        })
        expect(result[:content].first[:text]).to include('Pipeline deleted successfully via manage_pipeline')
      end
    end
  end

  describe '#detect_operation' do
    where(:arguments, :expected_operation) do
      [
        [{ list: true }, :list],
        [{ pipeline_id: 123, retry: true }, :retry],
        [{ pipeline_id: 123, cancel: true }, :cancel],
        [{ pipeline_id: 123, name: 'New Name' }, :update],
        [{ ref: 'main' }, :create],
        [{ pipeline_id: 123 }, :delete]
      ]
    end

    with_them do
      it 'detects the correct operation' do
        operation = service.send(:detect_operation, arguments)
        expect(operation).to eq(expected_operation)
      end
    end

    context 'with invalid arguments' do
      it 'raises ArgumentError when no operation can be determined' do
        expect { service.send(:detect_operation, { id: 'project-1' }) }.to raise_error(
          ArgumentError,
          /Cannot determine operation/
        )
      end
    end
  end

  describe '#select_tool' do
    where(:operation, :expected_tool_name) do
      [
        [:list, :list_pipelines],
        [:update, :update_pipeline],
        [:retry, :retry_pipeline],
        [:cancel, :cancel_pipeline],
        [:create, :create_pipeline],
        [:delete, :delete_pipeline]
      ]
    end

    with_them do
      it 'selects the correct tool based on operation' do
        tool = service.send(:select_tool, { operation: operation })
        expect(tool.name).to eq(expected_tool_name)
      end
    end
  end

  describe '#enhance_response_with_operation' do
    let(:response) do
      {
        content: [{ type: 'text', text: '{"id":1,"status":"created"}' }],
        structuredContent: { id: 1, status: 'created' },
        isError: false
      }
    end

    it 'adds operation action to content text for create operation' do
      result = service.send(
        :enhance_response_with_operation,
        response,
        operation: :create,
        tool_name: :create_pipeline,
        action_description: 'Pipeline created successfully via manage_pipeline.'
      )

      expect(result[:content].first[:text]).to include('Pipeline created successfully via manage_pipeline')
    end
  end
end
