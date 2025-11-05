# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::ApiTool, feature_category: :ai_agents do
  let(:app) { instance_double(Grape::Endpoint) }
  let(:mcp_settings) { { params: [:param1, :param2] } }
  let(:route_params) do
    {
      'param1' => { required: true, type: 'String', desc: 'First parameter' },
      'param2' => { required: false, type: 'Integer', desc: 'Second parameter' },
      'param3' => { required: true, type: 'Boolean', desc: 'Third parameter' }
    }
  end

  let(:route) do
    instance_double(Grape::Router::Route,
      app: app,
      description: 'Test API endpoint',
      params: route_params,
      request_method: 'POST',
      exec: [200, {}, ['{"success": true}']])
  end

  before do
    allow(app).to receive(:route_setting).with(:mcp).and_return(mcp_settings)
  end

  subject(:api_tool) { described_class.new(name: 'test_tool', route: route) }

  describe '#initialize' do
    it 'sets the name, route and settings' do
      expect(api_tool.name).to eq('test_tool')
      expect(api_tool.route).to eq(route)
      expect(api_tool.settings).to eq(mcp_settings)
      expect(api_tool.version).to eq('0.1.0')
    end

    context 'when version is specified in settings' do
      let(:mcp_settings) { { params: [:param1, :param2], version: '2.0.0' } }

      it 'uses the specified version' do
        expect(api_tool.version).to eq('2.0.0')
      end
    end
  end

  describe '#description' do
    it 'returns the route description' do
      expect(api_tool.description).to eq('Test API endpoint')
    end
  end

  describe '#input_schema' do
    context 'with standard types' do
      it 'returns a valid JSON schema with required fields' do
        schema = api_tool.input_schema

        expect(schema).to eq({
          type: 'object',
          properties: {
            'param1' => { type: 'string', description: 'First parameter' },
            'param2' => { type: 'integer', description: 'Second parameter' }
          },
          required: ['param1'],
          additionalProperties: false
        })
      end
    end

    context 'with boolean type' do
      let(:mcp_settings) { { params: [:param3] } }

      let(:route_params) do
        {
          'param3' => { required: true, type: 'Grape::API::Boolean', desc: 'Third parameter' }
        }
      end

      it 'converts Grape::API::Boolean to boolean' do
        schema = api_tool.input_schema

        expect(schema[:properties]['param3'][:type]).to eq('boolean')
      end
    end

    context 'when no required fields' do
      let(:route_params) do
        {
          'param1' => { required: false, type: 'String', desc: 'Optional parameter' }
        }
      end

      it 'returns empty required array' do
        schema = api_tool.input_schema

        expect(schema[:required]).to eq([])
      end
    end

    context 'when settings params filter out some route params' do
      let(:mcp_settings) { { params: [:param1] } }

      it 'only includes params specified in settings' do
        schema = api_tool.input_schema

        expect(schema[:properties].keys).to eq(['param1'])
      end
    end
  end

  describe '#execute' do
    let(:request) { instance_double(Rack::Request, env: request_env) }
    let(:request_env) { { 'grape.routing_args' => {} } }
    let(:params) { { arguments: { param1: 'value1', param2: 42 } } }

    context 'with successful response' do
      before do
        allow(route).to receive(:exec).with(request_env).and_return([200, {}, ['{"result": "success"}']])
      end

      it 'merges arguments into routing args, sets request method, and executes route' do
        result = api_tool.execute(request: request, params: params)

        expect(request_env['grape.routing_args']).to include(param1: 'value1', param2: 42)
        expect(request_env[Rack::REQUEST_METHOD]).to eq('POST')
        expect(result).to eq({
          content: [
            {
              text: "{\"result\": \"success\"}",
              type: "text"
            }
          ],
          isError: false,
          structuredContent: {
            "result" => "success"
          }
        })
      end
    end

    context 'with different HTTP methods' do
      let(:route) do
        instance_double(Grape::Router::Route,
          app: app,
          description: 'Test API endpoint',
          params: route_params,
          request_method: 'GET',
          exec: [200, {}, ['{"result": "success"}']])
      end

      before do
        allow(route).to receive(:exec).with(request_env).and_return([200, {}, ['{"result": "success"}']])
      end

      it 'sets the correct request method in environment' do
        api_tool.execute(request: request, params: params)

        expect(request_env[Rack::REQUEST_METHOD]).to eq('GET')
      end
    end

    context 'with error response' do
      before do
        allow(route).to receive(:exec).with(request_env).and_return([400, {}, ['{"error": "Bad request"}']])
      end

      it 'returns error response with parsed message' do
        result = api_tool.execute(request: request, params: params)

        expect(request_env[Rack::REQUEST_METHOD]).to eq('POST')
        expect(result).to eq(Mcp::Tools::Response.error('Bad request', { 'error' => 'Bad request' }))
      end
    end

    context 'with error response containing message field' do
      before do
        allow(route).to receive(:exec).with(request_env).and_return([422, {}, ['{"message": "Validation failed"}']])
      end

      it 'uses message field for error' do
        result = api_tool.execute(request: request, params: params)

        expect(result).to eq(Mcp::Tools::Response.error('Validation failed', { 'message' => 'Validation failed' }))
      end
    end

    context 'with error response without error or message fields' do
      before do
        allow(route).to receive(:exec).with(request_env).and_return([500, {}, ['{"details": "Internal error"}']])
      end

      it 'falls back to HTTP status message' do
        result = api_tool.execute(request: request, params: params)

        expect(result).to eq(Mcp::Tools::Response.error('HTTP 500', { 'details' => 'Internal error' }))
      end
    end

    context 'with invalid JSON response' do
      before do
        allow(route).to receive(:exec).with(request_env).and_return([500, {}, ['invalid json']])
      end

      it 'returns JSON parsing error' do
        result = api_tool.execute(request: request, params: params)

        expect(result[:content][0][:text]).to eq('Invalid JSON response')
      end
    end

    context 'with nil params' do
      let(:params) { {} }

      before do
        allow(route).to receive(:exec).with(request_env).and_return([200, {}, [{ 'result' => 'success' }.to_json]])
      end

      it 'handles nil arguments gracefully' do
        result = api_tool.execute(request: request, params: params)
        expect(request_env['grape.routing_args']).to eq({})
        expect(request_env[Rack::REQUEST_METHOD]).to eq('POST')
        expect(result).to eq({
          content: [
            {
              text: "{\"result\":\"success\"}",
              type: "text"
            }
          ],
          isError: false,
          structuredContent: { "result" => "success" }
        })
      end
    end

    context 'with filtered arguments based on settings' do
      let(:params) { { arguments: { param1: 'value1', param2: 42, unauthorized_param: 'hack' } } }

      before do
        allow(route).to receive(:exec).with(request_env).and_return([200, {}, [{ 'result' => 'success' }.to_json]])
      end

      it 'only includes params specified in settings' do
        api_tool.execute(request: request, params: params)

        expect(request_env['grape.routing_args']).to eq(param1: 'value1', param2: 42)
        expect(request_env['grape.routing_args']).not_to have_key(:unauthorized_param)
      end
    end
  end

  describe '#parse_type (private method)' do
    describe 'type parsing through input_schema' do
      let(:route_params) do
        {
          'string_param' => { required: false, type: 'String', desc: 'String param' },
          'integer_param' => { required: false, type: 'Integer', desc: 'Integer param' },
          'boolean_param' => { required: false, type: 'Grape::API::Boolean', desc: 'Boolean param' },
          'array_int_param' => { required: false, type: '[Integer]', desc: 'Array of integers param' },
          'array_string_param' => { required: false, type: '[String]', desc: 'Array of strings param' },
          'complex_array_param' => { required: false, type: '[String, Integer]', desc: 'Complex array param' }
        }
      end

      let(:mcp_settings) do
        {
          params: [
            :string_param, :integer_param, :boolean_param, :array_string_param, :array_int_param, :complex_array_param
          ]
        }
      end

      it 'correctly parses different types' do
        schema = api_tool.input_schema

        expect(schema[:properties]['string_param'][:type]).to eq('string')
        expect(schema[:properties]['integer_param'][:type]).to eq('integer')
        expect(schema[:properties]['boolean_param'][:type]).to eq('boolean')
        expect(schema[:properties]['array_int_param'][:type]).to eq('array')
        expect(schema[:properties]['array_int_param'][:items]).to eq({ type: 'integer' })
        expect(schema[:properties]['array_string_param'][:type]).to eq('string')
        expect(schema[:properties]['complex_array_param'][:type]).to eq('string')
      end
    end

    describe 'Array[Type] format parsing' do
      let(:route_params) do
        {
          'assignee_ids' => { required: false, type: 'Array[Integer]', desc: 'Array of user IDs' },
          'labels' => { required: false, type: 'Array[String]', desc: 'Array of label names' }
        }
      end

      let(:mcp_settings) { { params: [:assignee_ids, :labels] } }

      it 'converts Array[Integer] to proper JSON Schema array with integer items' do
        schema = api_tool.input_schema

        expect(schema[:properties]['assignee_ids']).to eq({
          type: 'array',
          items: { type: 'integer' },
          description: 'Array of user IDs'
        })
      end

      it 'converts Array[String] to proper JSON Schema array with string items' do
        schema = api_tool.input_schema

        expect(schema[:properties]['labels']).to eq({
          type: 'array',
          items: { type: 'string' },
          description: 'Array of label names'
        })
      end
    end
  end

  describe 'edge cases and error handling' do
    let(:request) { instance_double(Rack::Request, env: { 'grape.routing_args' => {} }) }
    let(:params) { { arguments: { param1: 'test' } } }

    context 'when route.exec raises an exception' do
      before do
        allow(route).to receive(:exec).and_raise(StandardError.new('Route execution failed'))
      end

      it 'does not rescue the exception' do
        expect { api_tool.execute(request: request, params: params) }
          .to raise_error(StandardError, 'Route execution failed')
      end
    end

    context 'when route has no params' do
      let(:route_params) { {} }

      it 'returns empty schema properties' do
        schema = api_tool.input_schema

        expect(schema[:properties]).to eq({})
        expect(schema[:required]).to eq([])
      end
    end

    context 'when settings has empty params array' do
      let(:mcp_settings) { { params: [] } }

      it 'returns empty schema properties' do
        schema = api_tool.input_schema

        expect(schema[:properties]).to eq({})
      end
    end
  end
end
