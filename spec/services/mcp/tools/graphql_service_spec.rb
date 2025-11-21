# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GraphqlService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }

  let(:test_graphql_tool_class) do
    Class.new do
      attr_reader :current_user, :params, :version

      def initialize(current_user:, params:, version: nil)
        @current_user = current_user
        @params = params
        @version = version
      end

      def execute
        Mcp::Tools::Response.success(
          [{ type: 'text', text: '{"result": "success"}' }],
          { 'result' => 'success' }
        )
      end
    end
  end

  # Create a test service implementation
  let(:test_service_class) do
    tool_class = test_graphql_tool_class

    Class.new(described_class) do
      register_version '0.1.0', {
        description: 'Test GraphQL service',
        input_schema: {
          type: 'object',
          properties: {
            test_param: { type: 'string' }
          },
          required: ['test_param']
        }
      }

      define_method(:graphql_tool_class) do
        tool_class
      end
    end
  end

  let(:service) { test_service_class.new(name: 'test_graphql_tool') }

  describe '#initialize' do
    it 'initializes with version' do
      expect(service.version).to eq('0.1.0')
    end

    it 'uses latest version when version not specified' do
      expect(service.version).to eq(test_service_class.latest_version)
    end

    context 'with specific version' do
      let(:service) { test_service_class.new(name: 'test_graphql_tool', version: '0.1.0') }

      it 'uses specified version' do
        expect(service.version).to eq('0.1.0')
      end
    end

    context 'when no versions are registered' do
      let(:unversioned_service_class) do
        Class.new(described_class) do
          def graphql_tool_class
            Object
          end
        end
      end

      it 'raises ArgumentError' do
        expect do
          unversioned_service_class.new(name: 'test')
        end.to raise_error(ArgumentError, /No versions registered/)
      end
    end

    context 'when invalid version is specified' do
      it 'raises ArgumentError' do
        expect do
          test_service_class.new(name: 'test', version: '99.99.99')
        end.to raise_error(ArgumentError, /Version 99.99.99 not found/)
      end
    end
  end

  describe '#set_cred' do
    it 'sets current_user' do
      service.set_cred(current_user: user, access_token: 'test_token_123')

      expect(service.instance_variable_get(:@current_user)).to eq(user)
      expect(service.instance_variable_get(:@access_token)).to be_nil
    end
  end

  describe '#description' do
    before do
      service.set_cred(current_user: user)
    end

    it 'returns description from version metadata' do
      expect(service.description).to eq('Test GraphQL service')
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: { test_param: 'value' } } }

    context 'when current_user is not set' do
      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result).to be_a(Hash)
        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end

    context 'when current_user is set' do
      before do
        service.set_cred(current_user: user)
      end

      it 'calls super and executes the service' do
        expect(service).to receive(:perform).and_call_original

        service.execute(request: request, params: params)
      end

      it 'executes GraphQL tool with correct parameters' do
        allow_next_instance_of(test_graphql_tool_class) do |tool|
          expect(tool).to receive(:execute).and_call_original
        end

        service.execute(request: request, params: params)
      end
    end
  end

  describe '#graphql_tool_class' do
    context 'when not implemented in subclass' do
      let(:unimplemented_service_class) do
        Class.new(described_class) do
          register_version '0.1.0', { description: 'test' }
        end
      end

      let(:base_service) { unimplemented_service_class.new(name: 'base') }

      it 'raises NotImplementedError' do
        expect do
          base_service.send(:graphql_tool_class)
        end.to raise_error(NotImplementedError, /graphql_tool_class must be implemented/)
      end
    end

    context 'when implemented in subclass' do
      before do
        service.set_cred(current_user: user)
      end

      it 'returns the GraphQL tool class' do
        expect(service.send(:graphql_tool_class)).to eq(test_graphql_tool_class)
      end
    end
  end

  describe '#perform_default' do
    context 'when not overridden in subclass' do
      let(:service_without_default) do
        tool_class = test_graphql_tool_class

        Class.new(described_class) do
          register_version '0.1.0', { description: 'test' }
          register_version '0.2.0', { description: 'test v2' }

          define_method(:graphql_tool_class) do
            tool_class
          end

          protected

          def perform_0_1_0(arguments)
            Mcp::Tools::Response.success([], { version: '0.1.0', args: arguments })
          end

          # No perform_0_2_0 defined - will fall back to perform_default
        end
      end

      it 'raises NoMethodError with version information' do
        service = service_without_default.new(name: 'test', version: '0.2.0')
        service.set_cred(current_user: user)

        expect do
          service.send(:perform, { test: 'value' })
        end.to raise_error(NoMethodError, /No implementation found for version 0.2.0/)
      end
    end

    context 'when overridden in subclass' do
      let(:service_with_default) do
        tool_class = test_graphql_tool_class

        Class.new(described_class) do
          register_version '0.1.0', { description: 'test' }
          register_version '0.2.0', { description: 'test v2' }

          define_method(:graphql_tool_class) do
            tool_class
          end

          protected

          def perform_0_1_0(arguments)
            Mcp::Tools::Response.success([], { version: '0.1.0', args: arguments })
          end

          # Override perform_default to provide fallback behavior
          def perform_default(arguments)
            execute_graphql_tool(arguments)
          end
        end
      end

      it 'uses the overridden implementation' do
        service = service_with_default.new(name: 'test', version: '0.2.0')
        service.set_cred(current_user: user)

        result = service.send(:perform, { test: 'value' })

        expect(result).to be_a(Hash)
        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to eq({ 'result' => 'success' })
      end

      it 'allows fallback to default for unimplemented versions' do
        service_v1 = service_with_default.new(name: 'test', version: '0.1.0')
        service_v2 = service_with_default.new(name: 'test', version: '0.2.0')

        service_v1.set_cred(current_user: user)
        service_v2.set_cred(current_user: user)

        result_v1 = service_v1.send(:perform, { test: 'v1' })
        result_v2 = service_v2.send(:perform, { test: 'v2' })

        # v0.1.0 uses specific implementation
        expect(result_v1[:structuredContent]).to eq({ version: '0.1.0', args: { test: 'v1' } })
        # v0.2.0 falls back to perform_default
        expect(result_v2[:structuredContent]).to eq({ 'result' => 'success' })
      end
    end
  end

  describe '#execute_graphql_tool' do
    before do
      service.set_cred(current_user: user)
    end

    it 'instantiates GraphQL tool with current_user, params and version' do
      expect(test_graphql_tool_class).to receive(:new).with(
        current_user: user,
        params: { test_param: 'value' },
        version: '0.1.0'
      ).and_call_original

      service.send(:execute_graphql_tool, { test_param: 'value' })
    end

    it 'calls execute on the GraphQL tool' do
      tool_instance = test_graphql_tool_class.new(current_user: user, params: {}, version: '0.1.0')
      allow(test_graphql_tool_class).to receive(:new).and_return(tool_instance)
      expect(tool_instance).to receive(:execute)

      service.send(:execute_graphql_tool, { test_param: 'value' })
    end

    it 'returns the result from GraphQL tool' do
      result = service.send(:execute_graphql_tool, { test_param: 'value' })

      expect(result).to be_a(Hash)
      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to eq({ 'result' => 'success' })
    end

    context 'with different service versions' do
      let(:versioned_service_class) do
        tool_class = test_graphql_tool_class

        Class.new(described_class) do
          register_version '0.1.0', { description: 'v0.1.0' }
          register_version '0.2.0', { description: 'v0.2.0' }

          define_method(:graphql_tool_class) do
            tool_class
          end

          protected

          def perform_0_1_0(arguments)
            execute_graphql_tool(arguments)
          end

          def perform_0_2_0(arguments)
            execute_graphql_tool(arguments)
          end
        end
      end

      it 'passes correct version to tool for v0.1.0' do
        service_v1 = versioned_service_class.new(name: 'test', version: '0.1.0')
        service_v1.set_cred(current_user: user)

        expect(test_graphql_tool_class).to receive(:new).with(
          current_user: user,
          params: { test: 'v1' },
          version: '0.1.0'
        ).and_call_original

        service_v1.send(:execute_graphql_tool, { test: 'v1' })
      end

      it 'passes correct version to tool for v0.2.0' do
        service_v2 = versioned_service_class.new(name: 'test', version: '0.2.0')
        service_v2.set_cred(current_user: user)

        expect(test_graphql_tool_class).to receive(:new).with(
          current_user: user,
          params: { test: 'v2' },
          version: '0.2.0'
        ).and_call_original

        service_v2.send(:execute_graphql_tool, { test: 'v2' })
      end
    end
  end

  describe 'version management' do
    let(:versioned_service_class) do
      tool_class = test_graphql_tool_class

      Class.new(described_class) do
        register_version '0.1.0', { description: 'v0.1.0' }
        register_version '0.2.0', { description: 'v0.2.0' }

        define_method(:graphql_tool_class) do
          tool_class
        end

        protected

        def perform_0_1_0(arguments)
          Mcp::Tools::Response.success([], { version: '0.1.0', args: arguments })
        end

        def perform_0_2_0(arguments)
          Mcp::Tools::Response.success([], { version: '0.2.0', args: arguments })
        end
      end
    end

    it 'supports version-specific perform methods' do
      service_v1 = versioned_service_class.new(name: 'test', version: '0.1.0')
      service_v2 = versioned_service_class.new(name: 'test', version: '0.2.0')

      service_v1.set_cred(current_user: user)
      service_v2.set_cred(current_user: user)

      result_v1 = service_v1.send(:perform, { test: 'v1' })
      result_v2 = service_v2.send(:perform, { test: 'v2' })

      expect(result_v1[:structuredContent]).to eq({ version: '0.1.0', args: { test: 'v1' } })
      expect(result_v2[:structuredContent]).to eq({ version: '0.2.0', args: { test: 'v2' } })
    end

    it 'uses latest version by default' do
      service = versioned_service_class.new(name: 'test')

      expect(service.version).to eq('0.2.0')
    end

    it 'lists all available versions' do
      expect(versioned_service_class.available_versions).to eq(%w[0.1.0 0.2.0])
    end

    it 'checks if version exists' do
      expect(versioned_service_class.version_exists?('0.1.0')).to be(true)
      expect(versioned_service_class.version_exists?('99.99.99')).to be(false)
    end

    it 'retrieves version metadata' do
      expect(versioned_service_class.version_metadata('0.1.0')).to eq({ description: 'v0.1.0' })
    end
  end
end
