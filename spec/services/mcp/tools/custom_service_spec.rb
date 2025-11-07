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
end
