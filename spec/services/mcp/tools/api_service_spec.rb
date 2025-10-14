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
    let(:api_response) do
      instance_double(Gitlab::HTTP::Response, body: response_body, success?: success, code: response_code)
    end

    before do
      allow(Gitlab::HTTP).to receive(:get).and_return(api_response)
      service.set_cred(access_token: oauth_token, current_user: nil)
    end

    context 'with single record response' do
      let(:success) { true }
      let(:response_code) { 200 }
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

    context 'with array response' do
      let(:service) { test_list_service_class.new(name: service_name) }
      let(:test_list_service_class) do
        Class.new(described_class) do
          def description
            'Test GET API tool'
          end

          def input_schema
            {
              type: 'object',
              properties: {
                id: { type: 'string' },
                page: { type: 'integer' },
                per_page: { type: 'integer' }
              },
              required: ['id']
            }
          end

          protected

          def perform(arguments = {})
            query = arguments.except(:id)
            http_get(access_token, "/api/v4/test/#{arguments[:id]}/list", query)
          end

          private

          def format_response_content(response)
            response.map do |item|
              { type: 'text', text: "web_url: #{item['web_url']}\ntitle: #{item['title']}" }
            end
          end
        end
      end

      let(:success) { true }
      let(:response_code) { 200 }
      let(:response_body) do
        [
          {
            id: "1",
            title: "A title",
            web_url: "https://gitlab.example.com/project/-/commit/1"
          },
          {
            id: "2",
            title: "Another title",
            web_url: "https://gitlab.example.com/project/-/commit/2"
          }
        ].to_json
      end

      it 'returns success response' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [
            { type: 'text', text: "web_url: https://gitlab.example.com/project/-/commit/1\ntitle: A title" },
            { type: 'text', text: "web_url: https://gitlab.example.com/project/-/commit/2\ntitle: Another title" }
          ],
          structuredContent: {
            items: [
              {
                'id' => '1',
                'title' => 'A title',
                'web_url' => 'https://gitlab.example.com/project/-/commit/1'
              },
              {
                'id' => '2',
                'title' => 'Another title',
                'web_url' => 'https://gitlab.example.com/project/-/commit/2'
              }
            ],
            metadata: {
              count: 2,
              has_more: false
            }
          },
          isError: false
        })
      end

      it 'makes request with correct parameters' do
        service.execute(request: nil, params: arguments)

        expect(Gitlab::HTTP).to have_received(:get).with(
          "#{Gitlab.config.gitlab.url}/api/v4/test/test-123/list",
          hash_including(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_token_123'
            },
            query: {}
          )
        )
      end

      it 'makes handles query parameters' do
        arguments[:arguments].merge!({ page: 1, per_page: 1 })

        service.execute(request: nil, params: arguments)

        expect(Gitlab::HTTP).to have_received(:get).with(
          "#{Gitlab.config.gitlab.url}/api/v4/test/test-123/list",
          hash_including(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_token_123'
            },
            query: { page: 1, per_page: 1 }
          )
        )
      end
    end

    context 'with error response' do
      let(:success) { false }
      let(:response_code) { 404 }
      let(:response_body) { { 'message' => 'Not found' }.to_json }

      it 'returns error response' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'Not found' }],
          structuredContent: { error: { 'message' => 'Not found' } },
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

    context 'with invalid JSON response' do
      let(:success) { false }
      let(:response_code) { 400 }
      let(:response_body) { '{invalid,json}' }

      it 'returns error response' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to match({
          content: [{ type: 'text', text: 'Invalid JSON response' }],
          structuredContent: { error: { message: /unexpected character/ } },
          isError: true
        })
      end
    end

    context 'with invalid path' do
      let(:invalid_arguments) { { arguments: { id: 'group-1/../admin/test-123' } } }
      let(:success) { false }
      let(:response_code) { 400 }
      let(:response_body) { { error: '400 Bad Request' }.to_json }

      it 'returns error response' do
        result = service.execute(request: nil, params: invalid_arguments)

        expect(result).to eq({
          content: [{ type: 'text', text: 'Validation error: path is invalid' }],
          structuredContent: {},
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
    let(:api_response) { instance_double(Gitlab::HTTP::Response, body: response_body, success?: true, code: 201) }
    let(:response_body) { { 'id' => 123, 'web_url' => 'https://example.com/issue/123' }.to_json }

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

    it 'raise access token is not set' do
      result = service.execute(request: nil, params: arguments)

      expect(result).to eq({
        content: [{ text: "ApiService: access token is not set", type: "text" }],
        structuredContent: {},
        isError: true
      })
    end
  end
end
