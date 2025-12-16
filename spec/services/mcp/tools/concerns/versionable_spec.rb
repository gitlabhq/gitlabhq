# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::Versionable, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::Versionable

      register_version '1.0.0', {
        description: 'First version of test tool',
        input_schema: {
          type: 'object',
          properties: { name: { type: 'string' } },
          required: ['name']
        }
      }

      register_version '1.1.0', {
        description: 'Enhanced version of test tool',
        input_schema: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            age: { type: 'integer' }
          },
          required: ['name']
        }
      }

      register_version '2.0.0', {
        description: 'Major version with breaking changes',
        input_schema: {
          type: 'object',
          properties: {
            full_name: { type: 'string' },
            metadata: { type: 'object' }
          },
          required: ['full_name']
        }
      }

      def initialize(version: nil)
        initialize_version(version)
      end
    end
  end

  describe 'VERSION_FORMAT constant' do
    it 'is defined' do
      expect(described_class::VERSION_FORMAT).to be_a(Regexp)
    end

    it 'matches valid semantic versions' do
      valid_versions = %w[0.0.0 1.0.0 1.2.3 10.20.30 99.99.99]

      expect(valid_versions).to all(match(described_class::VERSION_FORMAT))
    end

    it 'does not match invalid versions' do
      invalid_versions = ['1.0', '1', 'v1.0.0', '1.0.0-beta', '1.0.0.0', 'abc', '1.0.x', '']

      invalid_versions.each do |version|
        expect(version).not_to match(described_class::VERSION_FORMAT)
      end
    end
  end

  describe '.register_version' do
    it 'registers version metadata' do
      expect(test_class.version_metadata('1.0.0')).to eq({
        description: 'First version of test tool',
        input_schema: {
          type: 'object',
          properties: { name: { type: 'string' } },
          required: ['name']
        }
      })
    end

    it 'freezes the metadata' do
      metadata = test_class.version_metadata('1.0.0')
      expect(metadata).to be_frozen
    end

    context 'with invalid version format' do
      it 'raises ArgumentError for two-part version' do
        expect do
          test_class.register_version('1.0', { description: 'test' })
        end.to raise_error(ArgumentError, /Invalid version format: 1.0. Expected format: MAJOR.MINOR.PATCH/)
      end
    end
  end

  describe '.latest_version' do
    it 'returns the highest semantic version' do
      expect(test_class.latest_version).to eq('2.0.0')
    end

    context 'when no versions are registered' do
      let(:empty_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable
        end
      end

      it 'returns nil' do
        expect(empty_class.latest_version).to be_nil
      end
    end
  end

  describe '.available_versions' do
    it 'returns all versions sorted by semantic version' do
      expect(test_class.available_versions).to eq(['1.0.0', '1.1.0', '2.0.0'])
    end

    context 'when no versions are registered' do
      let(:empty_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable
        end
      end

      it 'returns empty array' do
        expect(empty_class.available_versions).to eq([])
      end
    end
  end

  describe '.version_exists?' do
    it 'returns true for existing versions' do
      expect(test_class.version_exists?('1.0.0')).to be true
      expect(test_class.version_exists?('1.1.0')).to be true
      expect(test_class.version_exists?('2.0.0')).to be true
    end

    it 'returns false for non-existing versions' do
      expect(test_class.version_exists?('0.9.0')).to be false
      expect(test_class.version_exists?('3.0.0')).to be false
    end

    context 'when no versions are registered' do
      let(:empty_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable
        end
      end

      it 'returns false' do
        expect(empty_class.version_exists?('1.0.0')).to be false
      end
    end
  end

  describe '.version_metadata' do
    it 'returns metadata for existing versions' do
      metadata = test_class.version_metadata('1.1.0')
      expect(metadata[:description]).to eq('Enhanced version of test tool')
      expect(metadata[:input_schema][:properties]).to have_key(:age)
    end

    it 'returns empty hash for non-existing versions' do
      expect(test_class.version_metadata('99.99.99')).to eq({})
    end

    context 'when no versions are registered' do
      let(:empty_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable
        end
      end

      it 'returns empty hash' do
        expect(empty_class.version_metadata('1.0.0')).to eq({})
      end
    end
  end

  describe '#initialize_version' do
    context 'when version is specified' do
      it 'uses the specified version' do
        instance = test_class.new(version: '1.0.0')
        expect(instance.version).to eq('1.0.0')
      end

      it 'raises error for non-existent version' do
        expect { test_class.new(version: '99.99.99') }
          .to raise_error(ArgumentError, 'Version 99.99.99 not found. Available: 1.0.0, 1.1.0, 2.0.0')
      end
    end

    context 'when version is not specified' do
      it 'uses the latest version' do
        instance = test_class.new
        expect(instance.version).to eq('2.0.0')
      end
    end

    context 'with invalid version is specified' do
      it 'raises error' do
        expect { test_class.new(version: '1.0') }
          .to raise_error(ArgumentError, /Invalid version format: 1.0. Expected format: MAJOR.MINOR.PATCH/)
      end
    end

    context 'when no versions are registered' do
      let(:empty_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          def initialize(version: nil)
            initialize_version(version)
          end
        end
      end

      it 'raises error' do
        expect { empty_class.new }
          .to raise_error(ArgumentError, /No versions registered for/)
      end
    end
  end

  describe '#version' do
    it 'returns the requested version' do
      instance = test_class.new(version: '1.1.0')
      expect(instance.version).to eq('1.1.0')
    end
  end

  describe '#description' do
    it 'returns description for the current version' do
      instance = test_class.new(version: '1.0.0')
      expect(instance.description).to eq('First version of test tool')
    end

    it 'raises error when description is not defined' do
      test_class_without_description = Class.new do
        include Mcp::Tools::Concerns::Versionable

        register_version '1.0.0', { input_schema: {} }

        def initialize(version: nil)
          initialize_version(version)
        end
      end

      instance = test_class_without_description.new(version: '1.0.0')
      expect { instance.description }
        .to raise_error(NoMethodError, 'Description not defined for version 1.0.0')
    end
  end

  describe '#input_schema' do
    it 'returns input schema for the current version' do
      instance = test_class.new(version: '1.1.0')
      expected_schema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'integer' }
        },
        required: ['name']
      }
      expect(instance.input_schema).to eq(expected_schema)
    end

    it 'raises error when input schema is not defined' do
      test_class_without_schema = Class.new do
        include Mcp::Tools::Concerns::Versionable

        register_version '1.0.0', { description: 'Test' }

        def initialize(version: nil)
          initialize_version(version)
        end
      end

      instance = test_class_without_schema.new(version: '1.0.0')
      expect { instance.input_schema }
        .to raise_error(NoMethodError, 'Input schema not defined for version 1.0.0')
    end
  end

  describe '#graphql_operation' do
    context 'when graphql_operation is defined in version metadata' do
      let(:graphql_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '1.0.0', {
            description: 'GraphQL tool v1',
            graphql_operation: 'query { test }'
          }

          register_version '2.0.0', {
            description: 'GraphQL tool v2',
            graphql_operation: 'query { testV2 { id name } }'
          }

          def initialize(version: nil)
            initialize_version(version)
          end
        end
      end

      it 'returns graphql_operation from metadata' do
        instance = graphql_class.new(version: '1.0.0')
        expect(instance.graphql_operation).to eq('query { test }')
      end

      it 'returns different operations for different versions' do
        instance_v1 = graphql_class.new(version: '1.0.0')
        instance_v2 = graphql_class.new(version: '2.0.0')

        expect(instance_v1.graphql_operation).to eq('query { test }')
        expect(instance_v2.graphql_operation).to eq('query { testV2 { id name } }')
      end
    end

    context 'when graphql_operation is not defined in metadata' do
      it 'raises NotImplementedError' do
        instance = test_class.new(version: '1.0.0')

        expect { instance.graphql_operation }
          .to raise_error(NotImplementedError, 'GraphQL operation not defined for version 1.0.0')
      end
    end
  end

  describe '#operation_name' do
    context 'when operation_name is defined in version metadata' do
      let(:graphql_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '1.0.0', {
            operation_name: 'createIssue',
            graphql_operation: 'mutation { createIssue }'
          }

          register_version '2.0.0', {
            operation_name: 'createWorkItem',
            graphql_operation: 'mutation { createWorkItem }'
          }

          def initialize(version: nil)
            initialize_version(version)
          end
        end
      end

      it 'returns operation_name from metadata' do
        instance = graphql_class.new(version: '1.0.0')
        expect(instance.operation_name).to eq('createIssue')
      end

      it 'returns different operation names for different versions' do
        instance_v1 = graphql_class.new(version: '1.0.0')
        instance_v2 = graphql_class.new(version: '2.0.0')

        expect(instance_v1.operation_name).to eq('createIssue')
        expect(instance_v2.operation_name).to eq('createWorkItem')
      end
    end

    context 'when operation_name is not defined in metadata' do
      it 'raises NotImplementedError' do
        instance = test_class.new(version: '1.0.0')

        expect { instance.operation_name }
          .to raise_error(NotImplementedError, 'operation_name must be defined')
      end
    end
  end

  describe '#graphql_operation_for_version' do
    context 'when graphql_operation is in version metadata' do
      let(:graphql_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '1.0.0', {
            description: 'GraphQL tool',
            graphql_operation: 'query { metadata }'
          }

          def initialize(version: nil)
            initialize_version(version)
          end
        end
      end

      it 'returns graphql_operation from metadata' do
        instance = graphql_class.new(version: '1.0.0')
        expect(instance.send(:graphql_operation_for_version)).to eq('query { metadata }')
      end
    end

    context 'when graphql_operation is not in metadata but method is overridden' do
      let(:graphql_class_with_override) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '1.0.0', {
            description: 'GraphQL tool',
            operation_name: 'test'
          }

          def initialize(version: nil)
            initialize_version(version)
          end

          def graphql_operation
            'query { overridden }'
          end
        end
      end

      it 'falls back to graphql_operation method' do
        instance = graphql_class_with_override.new(version: '1.0.0')
        expect(instance.send(:graphql_operation_for_version)).to eq('query { overridden }')
      end
    end

    context 'when neither metadata nor override exists' do
      it 'raises NotImplementedError' do
        instance = test_class.new(version: '1.0.0')

        expect { instance.send(:graphql_operation_for_version) }
          .to raise_error(NotImplementedError, /GraphQL operation not defined/)
      end
    end
  end

  describe '#build_variables_for_version' do
    context 'when version-specific build_variables method exists' do
      let(:graphql_class_with_version_variables) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '1.0.0', {
            operation_name: 'test',
            graphql_operation: 'query { test }'
          }

          register_version '2.0.0', {
            operation_name: 'test',
            graphql_operation: 'query { testV2 }'
          }

          attr_reader :params

          def initialize(version: nil, params: {})
            @params = params
            initialize_version(version)
          end

          def build_variables
            { default: true, id: params[:id] }
          end

          private

          def build_variables_1_0_0
            { version: '1.0.0', basic: true, id: params[:id] }
          end

          def build_variables_2_0_0
            {
              version: '2.0.0',
              advanced: true,
              id: params[:id],
              extra: params[:extra]
            }.compact
          end
        end
      end

      it 'calls version-specific method for v1.0.0' do
        instance = graphql_class_with_version_variables.new(version: '1.0.0', params: { id: '123' })
        result = instance.send(:build_variables_for_version)

        expect(result).to eq({ version: '1.0.0', basic: true, id: '123' })
      end

      it 'calls version-specific method for v2.0.0' do
        instance = graphql_class_with_version_variables.new(
          version: '2.0.0',
          params: { id: '456', extra: 'data' }
        )
        result = instance.send(:build_variables_for_version)

        expect(result).to eq({ version: '2.0.0', advanced: true, id: '456', extra: 'data' })
      end
    end

    context 'when version-specific method does not exist' do
      let(:graphql_class_fallback) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '3.0.0', {
            operation_name: 'test',
            graphql_operation: 'query { testV3 }'
          }

          attr_reader :params

          def initialize(version: nil, params: {})
            @params = params
            initialize_version(version)
          end

          def build_variables
            { fallback: true, id: params[:id] }
          end
        end
      end

      it 'falls back to build_variables method' do
        instance = graphql_class_fallback.new(version: '3.0.0', params: { id: '789' })
        result = instance.send(:build_variables_for_version)

        expect(result).to eq({ fallback: true, id: '789' })
      end
    end

    context 'when version-specific method exists but build_variables is not defined' do
      let(:graphql_class_no_fallback) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '1.0.0', {
            operation_name: 'test',
            graphql_operation: 'query { test }'
          }

          def initialize(version: nil)
            initialize_version(version)
          end

          private

          def build_variables_1_0_0
            { version: '1.0.0' }
          end
        end
      end

      it 'calls version-specific method' do
        instance = graphql_class_no_fallback.new(version: '1.0.0')
        result = instance.send(:build_variables_for_version)

        expect(result).to eq({ version: '1.0.0' })
      end
    end
  end

  describe '#version_method_suffix' do
    it 'converts version dots to underscores' do
      instance = test_class.new(version: '1.1.0')
      expect(instance.send(:version_method_suffix)).to eq('1_1_0')
    end
  end

  describe '#perform' do
    let(:test_service_class) do
      Class.new do
        include Mcp::Tools::Concerns::Versionable

        register_version '1.0.0', {
          description: 'First version of test tool',
          input_schema: {
            type: 'object',
            properties: { name: { type: 'string' } },
            required: ['name']
          }
        }

        register_version '1.1.0', {
          description: 'Enhanced version of test tool',
          input_schema: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              age: { type: 'integer' }
            },
            required: ['name']
          }
        }

        register_version '2.0.0', {
          description: 'Major version with breaking changes',
          input_schema: {
            type: 'object',
            properties: {
              full_name: { type: 'string' },
              metadata: { type: 'object' }
            },
            required: ['full_name']
          }
        }

        def initialize(version: nil)
          initialize_version(version)
        end

        protected

        def perform_1_0_0(arguments = {})
          {
            content: [{ type: 'text', text: "Hello #{arguments[:name]} (v1.0.0)" }],
            structuredContent: { version: '1.0.0', name: arguments[:name] }
          }
        end

        def perform_1_1_0(arguments = {})
          text = "Hello #{arguments[:name]}"
          text += ", age #{arguments[:age]}" if arguments[:age]
          text += " (v1.1.0)"

          {
            content: [{ type: 'text', text: text }],
            structuredContent: { version: '1.1.0', name: arguments[:name], age: arguments[:age] }
          }
        end

        def perform_2_0_0(arguments = {})
          {
            content: [{ type: 'text', text: "Hello #{arguments[:full_name]} (v2.0.0)" }],
            structuredContent: { version: '2.0.0', full_name: arguments[:full_name], metadata: arguments[:metadata] }
          }
        end
      end
    end

    context 'when version-specific method exists' do
      it 'calls the correct version method' do
        service = test_service_class.new(version: '1.0.0')
        result = service.send(:perform, { name: 'Alice' })

        expect(result[:content]).to match_array([{ type: 'text', text: 'Hello Alice (v1.0.0)' }])
        expect(result[:structuredContent][:version]).to eq('1.0.0')
      end

      it 'handles different versions correctly' do
        service_v1 = test_service_class.new(version: '1.1.0')
        service_v2 = test_service_class.new(version: '2.0.0')

        result_v1 = service_v1.send(:perform, { name: 'Bob', age: 25 })
        result_v2 = service_v2.send(:perform, { full_name: 'Bob Smith' })

        expect(result_v1[:content].first[:text]).to eq('Hello Bob, age 25 (v1.1.0)')
        expect(result_v2[:content].first[:text]).to eq('Hello Bob Smith (v2.0.0)')
      end
    end

    context 'when version-specific method does not exist' do
      let(:service_with_default_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '3.0.0', {
            description: 'Version without implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def initialize(version: nil)
            initialize_version(version)
          end

          def perform_default(_arguments = {})
            {
              content: [{ type: 'text', text: 'Fallback implementation' }],
              structuredContent: { fallback: true }
            }
          end
        end
      end

      it 'calls perform_default' do
        service = service_with_default_class.new(version: '3.0.0')
        result = service.send(:perform, {})

        expect(result[:content]).to match_array([{ type: 'text', text: 'Fallback implementation' }])
        expect(result[:structuredContent][:fallback]).to be true
      end
    end

    context 'when neither version method nor default exists' do
      let(:service_no_default_class) do
        Class.new do
          include Mcp::Tools::Concerns::Versionable

          register_version '4.0.0', {
            description: 'Version without any implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def initialize(version: nil)
            initialize_version(version)
          end
        end
      end

      it 'raises NoMethodError' do
        service = service_no_default_class.new(version: '4.0.0')
        expect { service.send(:perform, {}) }
          .to raise_error(NoMethodError, 'No implementation found for version 4.0.0')
      end
    end
  end
end
