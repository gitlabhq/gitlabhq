# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::CustomService, :aggregate_failures, feature_category: :mcp_server do
  let(:service_name) { 'test_custom_tool' }
  let(:current_user) { create(:user) }
  let(:project) { create :project, :repository }

  # Create a test service class that inherits from CustomService
  let(:test_service_class) do
    Class.new(described_class) do
      # Register version 1.0.0
      register_version '1.0.0', {
        description: 'First version of test tool',
        input_schema: {
          type: 'object',
          properties: { name: { type: 'string' } },
          required: ['name']
        }
      }

      # Register version 1.1.0
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

      # Register version 2.0.0
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

      def auth_ability
        :read_code
      end

      def auth_target(params)
        project_id = params.dig(:arguments, :project_id)
        find_project(project_id)
      end

      protected

      def perform_1_0_0(arguments = {})
        ::Mcp::Tools::Response.success(
          [{ type: 'text', text: "Hello #{arguments[:name]} (v1.0.0)" }],
          { version: '1.0.0', name: arguments[:name] }
        )
      end

      def perform_1_1_0(arguments = {})
        text = "Hello #{arguments[:name]}"
        text += ", age #{arguments[:age]}" if arguments[:age]
        text += " (v1.1.0)"

        ::Mcp::Tools::Response.success(
          [{ type: 'text', text: text }],
          { version: '1.1.0', name: arguments[:name], age: arguments[:age] }
        )
      end

      def perform_2_0_0(arguments = {})
        ::Mcp::Tools::Response.success(
          [{ type: 'text', text: "Hello #{arguments[:full_name]} (v2.0.0)" }],
          { version: '2.0.0', full_name: arguments[:full_name], metadata: arguments[:metadata] }
        )
      end

      def perform_default(arguments = {})
        ::Mcp::Tools::Response.success(
          [{ type: 'text', text: "Default implementation with #{arguments}" }],
          { version: 'default' }
        )
      end
    end
  end

  describe '.register_version' do
    it 'registers version metadata' do
      expect(test_service_class.version_metadata('1.0.0')).to eq({
        description: 'First version of test tool',
        input_schema: {
          type: 'object',
          properties: { name: { type: 'string' } },
          required: ['name']
        }
      })
    end

    it 'freezes the metadata' do
      metadata = test_service_class.version_metadata('1.0.0')
      expect(metadata).to be_frozen
    end
  end

  describe '.latest_version' do
    it 'returns the highest semantic version' do
      expect(test_service_class.latest_version).to eq('2.0.0')
    end

    context 'when no versions are registered' do
      let(:empty_service_class) { Class.new(described_class) }

      it 'returns nil' do
        expect(empty_service_class.latest_version).to be_nil
      end
    end
  end

  describe '.available_versions' do
    it 'returns all versions sorted by semantic version' do
      expect(test_service_class.available_versions).to eq(['1.0.0', '1.1.0', '2.0.0'])
    end

    context 'when no versions are registered' do
      let(:empty_service_class) { Class.new(described_class) }

      it 'returns empty array' do
        expect(empty_service_class.available_versions).to eq([])
      end
    end
  end

  describe '.version_exists?' do
    it 'returns true for existing versions' do
      expect(test_service_class.version_exists?('1.0.0')).to be true
      expect(test_service_class.version_exists?('1.1.0')).to be true
      expect(test_service_class.version_exists?('2.0.0')).to be true
    end

    it 'returns false for non-existing versions' do
      expect(test_service_class.version_exists?('0.9.0')).to be false
      expect(test_service_class.version_exists?('3.0.0')).to be false
    end

    context 'when no versions are registered' do
      let(:empty_service_class) { Class.new(described_class) }

      it 'returns false' do
        expect(empty_service_class.version_exists?('1.0.0')).to be false
      end
    end
  end

  describe '.version_metadata' do
    it 'returns metadata for existing versions' do
      metadata = test_service_class.version_metadata('1.1.0')
      expect(metadata[:description]).to eq('Enhanced version of test tool')
      expect(metadata[:input_schema][:properties]).to have_key(:age)
    end

    it 'returns empty hash for non-existing versions' do
      expect(test_service_class.version_metadata('99.99.99')).to eq({})
    end

    context 'when no versions are registered' do
      let(:empty_service_class) { Class.new(described_class) }

      it 'returns empty hash' do
        expect(empty_service_class.version_metadata('1.0.0')).to eq({})
      end
    end
  end

  describe '#initialize' do
    context 'when version is specified' do
      it 'uses the specified version' do
        service = test_service_class.new(name: service_name, version: '1.0.0')
        expect(service.version).to eq('1.0.0')
      end

      it 'raises error for non-existent version' do
        expect { test_service_class.new(name: service_name, version: '99.99.99') }
          .to raise_error(ArgumentError, 'Version 99.99.99 not found. Available: 1.0.0, 1.1.0, 2.0.0')
      end
    end

    context 'when version is not specified' do
      it 'uses the latest version' do
        service = test_service_class.new(name: service_name)
        expect(service.version).to eq('2.0.0')
      end
    end

    context 'when no versions are registered' do
      let(:empty_service_class) { Class.new(described_class) }

      it 'raises error' do
        expect { empty_service_class.new(name: service_name) }
          .to raise_error(ArgumentError, 'No versions registered for ')
      end
    end
  end

  describe '#version' do
    it 'returns the requested version' do
      service = test_service_class.new(name: service_name, version: '1.1.0')
      expect(service.version).to eq('1.1.0')
    end
  end

  describe '#description' do
    it 'returns description for the current version' do
      service = test_service_class.new(name: service_name, version: '1.0.0')
      expect(service.description).to eq('First version of test tool')
    end

    it 'raises error when description is not defined' do
      service_class = Class.new(described_class) do
        register_version '1.0.0', { input_schema: {} }
      end

      service = service_class.new(name: service_name, version: '1.0.0')
      expect { service.description }
        .to raise_error(NoMethodError, 'Description not defined for version 1.0.0')
    end
  end

  describe '#input_schema' do
    it 'returns input schema for the current version' do
      service = test_service_class.new(name: service_name, version: '1.1.0')
      expected_schema = {
        type: 'object',
        properties: {
          name: { type: 'string' },
          age: { type: 'integer' }
        },
        required: ['name']
      }
      expect(service.input_schema).to eq(expected_schema)
    end

    it 'raises error when input schema is not defined' do
      service_class = Class.new(described_class) do
        register_version '1.0.0', { description: 'Test' }
      end

      service = service_class.new(name: service_name, version: '1.0.0')
      expect { service.input_schema }
        .to raise_error(NoMethodError, 'Input schema not defined for version 1.0.0')
    end
  end

  describe '#execute' do
    let(:service) { test_service_class.new(name: service_name, version: '1.0.0') }

    context 'when custom tool perform without error' do
      let(:arguments) { { arguments: { project_id: project.id.to_s, name: 'Alice' } } }

      before do
        service.set_cred(access_token: nil, current_user: current_user)
        project.add_developer(current_user)
      end

      it 'returns success response' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ text: "Hello Alice (v1.0.0)", type: "text" }],
          structuredContent: { name: "Alice", version: "1.0.0" },
          isError: false
        })
      end
    end

    context 'when custom tool perform with error' do
      before do
        service.set_cred(access_token: nil, current_user: current_user)
        project.add_developer(current_user)

        allow(service).to receive(:perform).and_raise(StandardError, 'Something went wrong')
      end

      let(:arguments) { { arguments: { project_id: project.id.to_s, name: 'Alice' } } }

      it 'returns Tool execution failed response' do
        result = service.execute(request: nil, params: arguments)

        expect(result).to eq({
          content: [{ text: "Tool execution failed: Something went wrong", type: "text" }],
          structuredContent: {},
          isError: true
        })
      end
    end

    context 'when authorize! failed for custom tools' do
      let(:service) { test_service_class.new(name: service_name) }
      let(:current_user) { create(:user) }

      context 'when current_user is not set' do
        let(:arguments) { { arguments: {} } }

        it 'raise current_user is not set' do
          result = service.execute(request: nil, params: arguments)
          expect(result).to eq({
            content: [{ text: ": current_user is not set", type: "text" }],
            structuredContent: {},
            isError: true
          })
        end
      end

      context 'when current_user is set' do
        before do
          service.set_cred(current_user: current_user)
        end

        context 'when user lacks permission' do
          let(:arguments) { { arguments: { project_id: project.id.to_s } } }

          it 'raises Gitlab::Access::AccessDeniedError' do
            result = service.execute(request: nil, params: arguments)
            expect(result).to eq({
              content: [
                {
                  text: "Tool execution failed: CustomService: User #{current_user.id} " \
                    "does not have permission to read_code for target #{project.id}",
                  type: "text"
                }
              ],
              structuredContent: {},
              isError: true
            })
          end
        end
      end

      context 'when auth_ability is not implemented' do
        let(:test_service_class) do
          Class.new(described_class) do
            # Register version 1.0.0
            register_version '1.0.0', {
              description: 'First version of test tool',
              input_schema: {
                type: 'object',
                properties: { name: { type: 'string' } },
                required: ['name']
              }
            }

            def auth_target(params)
              params.dig(:arguments, :project_id)
            end
          end
        end

        before do
          service.set_cred(access_token: nil, current_user: current_user)
          project.add_developer(current_user)
        end

        context 'when current_user is not set' do
          let(:arguments) { { arguments: { project_id: project.id.to_s } } }

          it 'raise current_user is not set' do
            result = service.execute(request: nil, params: arguments)
            expect(result).to eq({
              content: [
                { text: "Tool execution failed: #auth_ability should be implemented in a subclass", type: "text" }
              ],
              structuredContent: {},
              isError: true
            })
          end
        end
      end

      context 'when auth_target is not implemented' do
        let(:test_service_class) do
          Class.new(described_class) do
            # Register version 1.0.0
            register_version '1.0.0', {
              description: 'First version of test tool',
              input_schema: {
                type: 'object',
                properties: { name: { type: 'string' } },
                required: ['name']
              }
            }

            def auth_ability
              :read_code
            end
          end
        end

        before do
          service.set_cred(access_token: nil, current_user: current_user)
          project.add_developer(current_user)
        end

        context 'when current_user is not set' do
          let(:arguments) { { arguments: { project_id: project.id.to_s } } }

          it 'raise current_user is not set' do
            result = service.execute(request: nil, params: arguments)
            expect(result).to eq({
              content: [
                { text: "Tool execution failed: #auth_target should be implemented in a subclass", type: "text" }
              ],
              structuredContent: {},
              isError: true
            })
          end
        end
      end
    end
  end

  describe '#perform' do
    context 'when version-specific method exists' do
      it 'calls the correct version method' do
        service = test_service_class.new(name: service_name, version: '1.0.0')
        result = service.send(:perform, { name: 'Alice' })

        expect(result[:content]).to match_array([{ type: 'text', text: 'Hello Alice (v1.0.0)' }])
        expect(result[:structuredContent][:version]).to eq('1.0.0')
      end

      it 'handles different versions correctly' do
        service_v1 = test_service_class.new(name: service_name, version: '1.1.0')
        service_v2 = test_service_class.new(name: service_name, version: '2.0.0')

        result_v1 = service_v1.send(:perform, { name: 'Bob', age: 25 })
        result_v2 = service_v2.send(:perform, { full_name: 'Bob Smith' })

        expect(result_v1[:content].first[:text]).to eq('Hello Bob, age 25 (v1.1.0)')
        expect(result_v2[:content].first[:text]).to eq('Hello Bob Smith (v2.0.0)')
      end
    end

    context 'when version-specific method does not exist' do
      let(:service_without_method_class) do
        Class.new(described_class) do
          register_version '3.0.0', {
            description: 'Version without implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }

          def perform_default(_arguments = {})
            ::Mcp::Tools::Response.success(
              [{ type: 'text', text: 'Fallback implementation' }],
              { fallback: true }
            )
          end
        end
      end

      it 'calls perform_default' do
        service = service_without_method_class.new(name: service_name, version: '3.0.0')
        result = service.send(:perform, {})

        expect(result[:content]).to match_array([{ type: 'text', text: 'Fallback implementation' }])
        expect(result[:structuredContent][:fallback]).to be true
      end
    end

    context 'when neither version method nor default exists' do
      let(:service_no_default_class) do
        Class.new(described_class) do
          register_version '4.0.0', {
            description: 'Version without any implementation',
            input_schema: { type: 'object', properties: {}, required: [] }
          }
        end
      end

      it 'raises NoMethodError' do
        service = service_no_default_class.new(name: service_name, version: '4.0.0')
        expect { service.send(:perform, {}) }
          .to raise_error(NoMethodError, 'No implementation found for version 4.0.0')
      end
    end
  end
end
