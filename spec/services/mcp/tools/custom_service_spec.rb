# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::CustomService, feature_category: :mcp_server do
  let(:service_name) { 'test_api_tool' }
  let(:current_user) { create(:user) }

  describe '#format_response_content' do
    let(:service) { described_class.new(name: service_name) }

    it 'raises NoMethodError' do
      expect { service.send(:format_response_content, {}) }.to raise_error(NoMethodError)
    end
  end

  context 'when custom tool perform without error' do
    before do
      service.set_cred(access_token: nil, current_user: current_user)
    end

    let(:arguments) { { arguments: {} } }
    let(:service) { test_get_service_class.new(name: service_name) }
    let(:test_get_service_class) do
      Class.new(described_class) do
        def description
          'Test custom tool'
        end

        def input_schema
          {
            type: 'object',
            properties: {},
            required: []
          }
        end

        protected

        def perform(_arguments = {})
          data = { version: "18.5.0-pre", revision: "2b34553de07" }
          formatted_content = [{ type: 'text', text: data[:version] }]
          ::Mcp::Tools::Response.success(formatted_content, data)
        end
      end
    end

    let(:success) { true }
    let(:response_code) { 200 }

    it 'returns success response' do
      result = service.execute(request: nil, params: arguments)

      expect(result).to eq({
        content: [{ text: "18.5.0-pre", type: "text" }],
        structuredContent: { revision: "2b34553de07", version: "18.5.0-pre" },
        isError: false
      })
    end
  end

  context 'when custom tool perform with error' do
    before do
      service.set_cred(access_token: nil, current_user: current_user)
    end

    let(:arguments) { { arguments: {} } }
    let(:service) { test_get_service_class.new(name: service_name) }
    let(:test_get_service_class) do
      Class.new(described_class) do
        def description
          'Test custom tool'
        end

        def input_schema
          {
            type: 'object',
            properties: {},
            required: []
          }
        end

        protected

        def perform(_arguments = {})
          raise StandardError, 'Something went wrong'
        end
      end
    end

    let(:success) { true }
    let(:response_code) { 200 }

    it 'returns success response' do
      result = service.execute(request: nil, params: arguments)

      expect(result).to eq({
        content: [{ text: "Tool execution failed: Something went wrong", type: "text" }],
        structuredContent: {},
        isError: true
      })
    end
  end

  context 'when current_user is not set' do
    let(:arguments) { { arguments: {} } }
    let(:service) { test_get_service_class.new(name: service_name) }
    let(:test_get_service_class) do
      Class.new(described_class) do
        def description
          'Test custom tool'
        end
      end
    end

    let(:success) { true }
    let(:response_code) { 200 }

    it 'raise current_user is not set' do
      result = service.execute(request: nil, params: arguments)

      expect(result).to eq({
        content: [{ text: "CustomService: current_user is not set", type: "text" }],
        structuredContent: {},
        isError: true
      })
    end
  end

  describe '#find_project' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project) { create(:project, :public, namespace: namespace) }
    let(:service) { test_get_service_class.new(name: service_name) }
    let(:test_get_service_class) do
      Class.new(described_class) do
        def description
          'Test custom tool'
        end
      end
    end

    context 'with project ID' do
      it 'finds the project' do
        found = service.find_project(project.id.to_s)
        expect(found).to eq(project)
      end
    end

    context 'with project full path' do
      it 'finds the project' do
        found = service.find_project(project.full_path.to_s)
        expect(found).to eq(project)
      end
    end
  end
end
