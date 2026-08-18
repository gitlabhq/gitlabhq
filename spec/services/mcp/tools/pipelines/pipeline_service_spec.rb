# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Pipelines::PipelineService, feature_category: :mcp_server do
  let(:update_tool) { instance_double(Mcp::Tools::Base::ApiTool, name: :update_pipeline) }
  let(:delete_tool) { instance_double(Mcp::Tools::Base::ApiTool, name: :delete_pipeline) }
  let(:tools) { [update_tool, delete_tool] }
  let(:service) { described_class.new(tools: tools) }

  describe '.tool_name' do
    it 'returns the correct tool name' do
      expect(described_class.tool_name).to eq('manage_pipeline')
    end
  end

  describe '#description' do
    it 'returns the correct description' do
      description = service.description

      %w[Update Delete].each do |action|
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
    it 'matches the expected contract' do
      expect(service.input_schema).to eq(
        {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'ID or URL-encoded path of the project'
            },
            pipeline_id: {
              type: 'integer',
              description: 'ID of the pipeline to update or delete.'
            },
            name: {
              type: 'string',
              description: 'New name for the pipeline (for update operation)'
            }
          },
          required: %w[id pipeline_id],
          additionalProperties: false
        }
      )
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
      let(:arguments) { { id: 'project-1', pipeline_id: 123, name: 'New Pipeline Name' } }
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
      let(:arguments) { { id: 'project-1', pipeline_id: 123, name: 'New Pipeline Name' } }

      before do
        allow(update_tool).to receive(:execute).and_raise(StandardError, 'Pipeline update failed')
      end

      it 'returns execution error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Tool execution failed: Pipeline update failed')
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
        [{ pipeline_id: 123, name: 'New Name' }, :update],
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
        [:update, :update_pipeline],
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
        content: [{ type: 'text', text: '{"id":1,"status":"updated"}' }],
        structuredContent: { id: 1, status: 'updated' },
        isError: false
      }
    end

    it 'adds operation action to content text for update operation' do
      result = service.send(
        :enhance_response_with_operation,
        response,
        operation: :update,
        tool_name: :update_pipeline,
        action_description: 'Pipeline updated successfully via manage_pipeline.'
      )

      expect(result[:content].first[:text]).to include('Pipeline updated successfully via manage_pipeline')
    end
  end
end
