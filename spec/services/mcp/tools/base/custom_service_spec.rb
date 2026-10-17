# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Base::CustomService, :aggregate_failures, feature_category: :mcp_server do
  let(:service_name) { 'test_custom_tool' }
  let(:current_user) { create(:user) }
  let(:project) { create :project }

  # Create a test service class that inherits from CustomService
  let(:test_service_class) do
    Class.new(described_class) do
      # Register version 1.0.0
      register_version '1.0.0', {
        description: 'First version of test tool',
        input_schema: {
          type: 'object',
          properties: { name: { type: 'string' }, project_id: { type: 'string' } },
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
            age: { type: 'integer' },
            project_id: { type: 'string' }
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
            metadata: { type: 'object' },
            project_id: { type: 'string' }
          },
          required: ['full_name']
        }
      }

      def auth_ability
        :read_code
      end

      def auth_target(params)
        project_id = params.dig(:arguments, :project_id)
        find_project!(project_id)
      end

      protected

      def perform_v1_0_0(arguments = {})
        ::Mcp::Tools::Base::Response.success(
          [{ type: 'text', text: "Hello #{arguments[:name]} (v1.0.0)" }],
          { version: '1.0.0', name: arguments[:name] }
        )
      end

      def perform_v1_1_0(arguments = {})
        text = "Hello #{arguments[:name]}"
        text += ", age #{arguments[:age]}" if arguments[:age]
        text += " (v1.1.0)"

        ::Mcp::Tools::Base::Response.success(
          [{ type: 'text', text: text }],
          { version: '1.1.0', name: arguments[:name], age: arguments[:age] }
        )
      end

      def perform_v2_0_0(arguments = {})
        ::Mcp::Tools::Base::Response.success(
          [{ type: 'text', text: "Hello #{arguments[:full_name]} (v2.0.0)" }],
          { version: '2.0.0', full_name: arguments[:full_name], metadata: arguments[:metadata] }
        )
      end

      def perform_default(arguments = {})
        ::Mcp::Tools::Base::Response.success(
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
        service.set_cred(access_token: build_stubbed(:personal_access_token, user: current_user),
          current_user: current_user)
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
        service.set_cred(access_token: build_stubbed(:personal_access_token, user: current_user),
          current_user: current_user)
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
            isError: true,
            reason: :unauthorized
          })
        end
      end

      context 'when current_user is set' do
        before do
          service.set_cred(current_user: current_user)
        end

        context 'when user lacks permission' do
          let(:current_user) { create(:user, guest_of: project) }
          let(:arguments) { { arguments: { project_id: project.id.to_s } } }

          it 'returns a non-leaky error without revealing user or target details' do
            result = service.execute(request: nil, params: arguments)

            expect(result[:isError]).to be true
            expect(result[:reason]).to eq(:unauthorized)
            expect(result[:content].first[:text])
              .to eq("Tool execution failed: #{service_name}: not found or access denied")
          end
        end

        context 'when the user cannot read the project' do
          let(:current_user) { create(:user) }
          let(:arguments) { { arguments: { project_id: project.id.to_s } } }

          it 'logs the denial while telling the agent only that it was not found' do
            result = service.execute(request: nil, params: arguments)

            expect(result).to eq({
              content: [
                { text: "Tool execution failed: Project '#{project.id}' not found or inaccessible", type: "text" }
              ],
              structuredContent: {},
              isError: true,
              reason: :unauthorized
            })
          end

          it 'does not report an expected denial to error tracking' do
            expect(::Gitlab::ErrorTracking).not_to receive(:track_exception)

            service.execute(request: nil, params: arguments)
          end
        end

        context 'when project_id is not a string' do
          let(:arguments) { { arguments: { project_id: project.id } } }

          it 'reports bad_request' do
            result = service.execute(request: nil, params: arguments)

            expect(result[:content].first[:text]).to eq('Tool execution failed: project_id must be a string')
            expect(Mcp::Tools::Base::Response.error_reason(result)).to eq(:bad_request)
          end
        end

        context 'when the project does not exist' do
          let(:current_user) { create(:user) }
          let(:arguments) { { arguments: { project_id: non_existing_record_id.to_s } } }

          it 'reports not_found, with the same message a denial produces' do
            result = service.execute(request: nil, params: arguments)

            expect(result).to eq({
              content: [
                {
                  text: "Tool execution failed: Project '#{non_existing_record_id}' not found or inaccessible",
                  type: "text"
                }
              ],
              structuredContent: {},
              isError: true,
              reason: :not_found
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

    context 'with an access token' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:current_user) { create(:user, developer_of: project) }

      let(:declares_granular_permissions) { true }
      let(:service) { test_service_class.new(name: service_name, version: '1.0.0') }
      let(:arguments) { { arguments: { project_id: project.id.to_s, name: 'Alice' } } }
      let(:boundary) { ::Authz::Boundary.for(project) }
      let(:denial_prefix) do
        'Tool execution failed: Access denied: This operation requires a fine-grained personal access token'
      end

      subject(:result) { service.execute(request: nil, params: arguments) }

      before do
        test_service_class.define_method(:granular_permissions) { [:read_code] } if declares_granular_permissions
        service.set_cred(current_user: current_user, access_token: token)
      end

      context 'with a granular token that has the permission' do
        let(:token) { create(:granular_pat, user: current_user, boundary: boundary, permissions: :read_code) }

        it 'runs the tool' do
          expect(result[:isError]).to be(false)
        end

        it 'looks up the target once' do
          expect(service).to receive(:auth_target).once.and_call_original

          result
        end
      end

      context 'with a granular token that lacks the permission' do
        let(:token) { create(:granular_pat, user: current_user, boundary: boundary, permissions: :read_release) }

        it 'returns an unauthorized error and records the denied permission' do
          expect(::Gitlab::ErrorTracking).not_to receive(:track_exception)

          expect(result[:isError]).to be(true)
          expect(result[:reason]).to eq(:unauthorized)
          expect(result[:content].first[:text]).to start_with(denial_prefix)
          expect(::Current.granular_denied_permissions).to eq([:read_code])
        end
      end

      context 'when the tool declares no granular permissions' do
        let(:declares_granular_permissions) { false }
        let(:token) { create(:granular_pat, user: current_user, boundary: boundary, permissions: :read_code) }

        it 'denies the granular token' do
          expect(result[:reason]).to eq(:unauthorized)
          expect(result[:content].first[:text])
            .to eq("Tool execution failed: Access denied: This operation doesn't support " \
              "fine-grained personal access tokens.")
        end
      end

      context 'when the boundary cannot be resolved' do
        let(:token) { create(:granular_pat, user: current_user, boundary: boundary, permissions: :read_code) }

        before do
          allow(service).to receive(:granular_boundary).and_return(nil)
        end

        it 'returns not found' do
          expect(result[:reason]).to eq(:not_found)
          expect(result[:content].first[:text])
            .to eq("Tool execution failed: #{service_name}: not found or access denied")
        end
      end

      context 'without a token' do
        let(:token) { nil }

        it 'denies the call' do
          expect(result[:reason]).to eq(:unauthorized)
          expect(result[:content].first[:text])
            .to eq("Tool execution failed: #{service_name}: not found or access denied")
        end
      end

      context 'with a legacy token' do
        let(:token) { create(:personal_access_token, user: current_user, scopes: [:mcp]) }

        it 'runs the tool' do
          expect(result[:isError]).to be(false)
        end

        context 'when the namespace enforces granular tokens' do
          before do
            stub_feature_flags(granular_personal_access_tokens_enforcement_saas: group)
            ::NamespaceSetting.find_by!(namespace_id: group.id)
              .update!(enforce_granular_tokens: true, granular_tokens_enforced_after: Date.current)
          end

          it 'denies the token' do
            expect(result[:reason]).to eq(:unauthorized)
            expect(result[:content].first[:text]).to start_with(denial_prefix)
          end
        end
      end
    end
  end

  describe '#granular_boundary' do
    let(:service) { test_service_class.new(name: service_name) }

    it 'returns a project or group target as is' do
      group = build_stubbed(:group)

      expect(service.granular_boundary(project)).to eq(project)
      expect(service.granular_boundary(group)).to eq(group)
    end

    it 'returns the project of any other target' do
      merge_request = build_stubbed(:merge_request, project: project)

      expect(service.granular_boundary(merge_request)).to eq(project)
    end

    it 'raises for a target without a project' do
      expect { service.granular_boundary(build_stubbed(:user)) }
        .to raise_error(NoMethodError, /#granular_boundary should be implemented for User/)
    end
  end
end
