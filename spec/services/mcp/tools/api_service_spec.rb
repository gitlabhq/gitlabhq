# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::ApiService, feature_category: :mcp_server do
  let(:service_name) { 'test_api_tool' }
  let(:oauth_token) { 'test_token_123' }

  describe '#format_response_content' do
    let(:service) { described_class.new(name: service_name) }

    it 'raises NoMethodError' do
      expect { service.send(:format_response_content, {}) }.to raise_error(NoMethodError)
    end
  end

  describe 'GET requests' do
    let(:service) { test_get_service_class.new(name: service_name) }

    let(:test_get_service_class) do
      Class.new(described_class) do
        def description
          'Test GET API tool'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: { type: 'string' }
            },
            required: ['id']
          }
        end

        protected

        def perform(arguments = {})
          http_get(access_token, "/api/v4/test/#{arguments[:id]}")
        end

        private

        def format_response_content(response)
          [{ type: 'text', text: response['web_url'] }]
        end
      end
    end

    let(:arguments) { { arguments: { id: 'test-123' } } }
    let(:success) { true }
    let(:response_code) { 200 }
    let(:response_body) { { 'web_url' => 'test' }.to_json }

    let(:api_response) do
      instance_double(Gitlab::HTTP::Response, body: response_body, success?: success, code: response_code)
    end

    before do
      allow(Gitlab::HTTP).to receive(:get).and_return(api_response)
      service.set_cred(access_token: oauth_token, current_user: nil)
    end

    it 'handles JSON parser errors gracefully' do
      allow(Gitlab::Json).to receive(:safe_parse).and_raise(JSON::ParserError.new('boom'))

      result = service.execute(request: nil, params: arguments)

      expect(result).to include(isError: true)
      expect(result[:content]).to include(
        hash_including(text: 'Invalid JSON response')
      )
    end

    it 'sets verify when in dev or test env' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)

      service.execute(request: nil, params: arguments)

      expect(Gitlab::HTTP).to have_received(:get).with(
        anything,
        hash_including(:verify)
      )
    end

    it 'does not set verify when not in dev or test env' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      service.execute(request: nil, params: arguments)

      expect(Gitlab::HTTP).to have_received(:get).with(
        anything,
        hash_not_including(:verify)
      )
    end

    it 'returns error when parsed_response is nil on success' do
      allow(Gitlab::Json).to receive(:safe_parse).and_return(nil)

      result = service.execute(request: nil, params: arguments)

      expect(result[:content]).to include(hash_including(text: 'Invalid JSON response'))
    end

    context 'with error response and nil parsed_response' do
      let(:success) { false }
      let(:response_code) { 500 }
      let(:response_body) { '' }

      before do
        allow(Gitlab::Json).to receive(:safe_parse).and_return(nil)
      end

      it 'falls back to HTTP code when parsed_response is nil' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'HTTP 500' }],
          structuredContent: {},
          isError: true
        })
      end
    end

    context 'with error response and parsed_response missing message key' do
      let(:success) { false }
      let(:response_code) { 500 }
      let(:response_body) { '{"not_message":"value"}' }

      before do
        allow(Gitlab::Json).to receive(:safe_parse).and_return({ 'not_message' => 'value' })
      end

      it 'evaluates left side of || and falls back to HTTP code' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'HTTP 500' }],
          structuredContent: { error: { 'not_message' => 'value' } },
          isError: true
        })
      end
    end

    context 'with single record response' do
      let(:response_body) { { 'web_url' => 'https://example.com/test', 'id' => 1 }.to_json }

      it 'returns success response' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'https://example.com/test' }],
          structuredContent: { 'web_url' => 'https://example.com/test', 'id' => 1 },
          isError: false
        })
      end

      it 'makes request with correct parameters' do
        service.execute(request: nil, params: arguments)

        expect(Gitlab::HTTP).to have_received(:get).with(
          "#{Gitlab.config.gitlab.url}/api/v4/test/test-123",
          hash_including(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_token_123'
            }
          )
        )
      end
    end

    context 'with error response with message' do
      let(:success) { false }
      let(:response_code) { 400 }
      let(:response_body) { { 'message' => 'Bad request' }.to_json }

      it 'returns API error message' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'Bad request' }],
          structuredContent: { error: { 'message' => 'Bad request' } },
          isError: true
        })
      end
    end

    context 'with error response without message' do
      let(:success) { false }
      let(:response_code) { 500 }
      let(:response_body) { {}.to_json }

      it 'returns generic error message' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'HTTP 500' }],
          structuredContent: { error: {} },
          isError: true
        })
      end
    end
  end

  describe 'POST requests' do
    let(:test_post_service_class) do
      Class.new(described_class) do
        def description
          'Test POST API tool'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: { type: 'string' },
              title: { type: 'string' }
            },
            required: %w[id title]
          }
        end

        protected

        def perform(arguments = {})
          path = "/api/v4/projects/#{arguments[:id]}/issues"
          body = arguments.except(:id)
          http_post(access_token, path, body)
        end

        private

        def format_response_content(response)
          [{ type: 'text', text: response['web_url'] }]
        end
      end
    end

    let(:service) { test_post_service_class.new(name: 'test_post_tool') }
    let(:arguments) { { arguments: { id: 'project-1', title: 'New Issue' } } }
    let(:response_body) { { 'id' => 123, 'web_url' => 'https://example.com/issue/123' }.to_json }

    let(:api_response) do
      instance_double(Gitlab::HTTP::Response, body: response_body, success?: true, code: 201)
    end

    before do
      allow(Gitlab::HTTP).to receive(:post).and_return(api_response)
      service.set_cred(access_token: oauth_token, current_user: nil)
    end

    it 'makes POST request with body' do
      service.execute(request: nil, params: arguments)

      expect(Gitlab::HTTP).to have_received(:post).with(
        "#{Gitlab.config.gitlab.url}/api/v4/projects/project-1/issues",
        hash_including(
          body: { title: 'New Issue' }.to_json,
          headers: hash_including('Content-Type' => 'application/json')
        )
      )
    end

    it 'returns success response' do
      result = service.execute(request: nil, params: arguments)

      expect(result).to eq({
        content: [{ type: 'text', text: 'https://example.com/issue/123' }],
        structuredContent: { 'id' => 123, 'web_url' => 'https://example.com/issue/123' },
        isError: false
      })
    end
  end

  describe 'When token is not set' do
    let(:arguments) { { arguments: { id: 'test-123' } } }

    let(:service) { described_class.new(name: 'test_api_tool') }

    it 'returns error when access token is not set' do
      result = service.execute(request: nil, params: arguments)

      expect(result).to eq({
        content: [{ text: "ApiService: access token is not set", type: "text" }],
        structuredContent: {},
        isError: true
      })
    end
  end
end
