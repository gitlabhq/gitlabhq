# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::BaseService, feature_category: :mcp_server do
  let(:service_name) { 'test_tool' }
  let(:service) { described_class.new(name: service_name) }

  let(:test_service_class) do
    Class.new(described_class) do
      def description
        'Test tool for specs'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            required_field: { type: 'string' },
            optional_field: { type: 'integer' }
          },
          required: ['required_field']
        }
      end

      def version
        '1.0.0'
      end

      protected

      def perform(arguments, _query = {})
        raise StandardError, 'Something went wrong' if arguments[:required_field] == 'error'

        formatted_content = [{ type: 'text', text: 'Success' }]
        Mcp::Tools::Response.success(formatted_content, { processed: true })
      end
    end
  end

  let(:test_service) { test_service_class.new(name: service_name) }

  describe '#description' do
    it 'raises NoMethodError' do
      expect { service.description }.to raise_error(NoMethodError)
    end
  end

  describe '#input_schema' do
    it 'raises NoMethodError' do
      expect { service.input_schema }.to raise_error(NoMethodError)
    end
  end

  describe '#version' do
    it 'raises NoMethodError' do
      expect { service.version }.to raise_error(NoMethodError)
    end
  end

  describe '#perform' do
    it 'raises NoMethodError' do
      expect { service.send(:perform, {}, {}) }.to raise_error(NoMethodError)
    end
  end

  describe '#set_cred' do
    it 'raises NoMethodError' do
      expect { service.set_cred(current_user: nil, access_token: nil) }.to raise_error(NoMethodError)
    end
  end

  describe '#available?' do
    it 'returns true' do
      expect(service.available?).to be true
    end
  end

  describe '#to_h' do
    it 'returns tool metadata' do
      result = test_service.to_h

      expect(result).to eq({
        name: service_name,
        description: 'Test tool for specs',
        inputSchema: {
          type: 'object',
          properties: {
            required_field: { type: 'string' },
            optional_field: { type: 'integer' }
          },
          required: ['required_field']
        }
      })
    end
  end

  describe '#execute' do
    let(:access_token) { 'test_token' }

    context 'with valid arguments' do
      let(:arguments) { { arguments: { required_field: 'test' } } }

      it 'returns success response' do
        result = test_service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'Success' }],
          structuredContent: { processed: true },
          isError: false
        })
      end
    end

    context 'with missing required field' do
      let(:arguments) { { arguments: { optional_field: 123 } } }

      it 'returns validation error' do
        result = test_service.execute(request: nil, params: arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Validation error: required_field is missing')
      end
    end

    context 'with invalid field type' do
      let(:arguments) { { arguments: { required_field: 123 } } }

      it 'returns validation error' do
        result = test_service.execute(request: nil, params: arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error:')
      end
    end

    context 'when perform raises an error' do
      let(:arguments) { { arguments: { required_field: 'error' } } }

      it 'returns execution error' do
        result = test_service.execute(request: nil, params: arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq('Tool execution failed: Something went wrong')
      end
    end

    context 'with nil arguments' do
      let(:arguments) { { arguments: nil } }

      it 'returns validation error' do
        result = test_service.execute(request: nil, params: arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('required_field is missing')
      end
    end
  end
end
