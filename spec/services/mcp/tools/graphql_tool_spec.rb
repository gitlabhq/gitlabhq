# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GraphqlTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let(:params) { { project_path: 'gitlab-org/gitlab' } }

  # Create a test implementation with versioning
  let(:test_tool_class) do
    Class.new(described_class) do
      register_version '1.0.0', {
        operation_name: 'testMutation',
        graphql_operation: <<~GRAPHQL
          mutation($input: TestInput!) {
            testMutation(input: $input) {
              result { id }
              errors
            }
          }
        GRAPHQL
      }

      register_version '2.0.0', {
        operation_name: 'testMutation',
        graphql_operation: <<~GRAPHQL
          mutation($input: TestInput!) {
            testMutation(input: $input) {
              result { id title description }
              errors
            }
          }
        GRAPHQL
      }

      def build_variables
        { input: { projectPath: params[:project_path] } }
      end

      private

      def build_variables_2_0_0
        {
          input: {
            projectPath: params[:project_path],
            includeArchived: params[:include_archived]
          }.compact
        }
      end
    end
  end

  let(:tool) { test_tool_class.new(current_user: user, params: params) }

  describe '#initialize' do
    it 'sets current_user and params' do
      expect(tool.current_user).to eq(user)
      expect(tool.params).to eq(params)
    end

    it 'initializes with latest version by default' do
      expect(tool.version).to eq('2.0.0')
    end

    context 'when version is specified' do
      let(:tool) { test_tool_class.new(current_user: user, params: params, version: '1.0.0') }

      it 'uses the specified version' do
        expect(tool.version).to eq('1.0.0')
      end
    end

    context 'when invalid version is specified' do
      it 'raises ArgumentError' do
        expect do
          test_tool_class.new(current_user: user, params: params, version: '99.99.99')
        end.to raise_error(ArgumentError, 'Version 99.99.99 not found. Available: 1.0.0, 2.0.0')
      end
    end
  end

  describe '#graphql_operation' do
    context 'when not implemented in subclass and not in version metadata' do
      let(:tool_without_operation) do
        Class.new(described_class) do
          register_version '1.0.0', { operation_name: 'test' }

          def build_variables
            {}
          end
        end.new(current_user: user, params: params)
      end

      it 'raises NotImplementedError' do
        expect { tool_without_operation.graphql_operation }.to raise_error(NotImplementedError)
      end
    end

    context 'when defined in version metadata' do
      it 'returns the GraphQL operation from metadata' do
        operation = tool.graphql_operation

        expect(operation).to include('testMutation')
        expect(operation).to include('result { id title description }')
      end
    end
  end

  describe '#operation_name' do
    context 'when not defined in version metadata' do
      let(:tool_without_operation_name) do
        Class.new(described_class) do
          register_version '1.0.0', { graphql_operation: 'query { test }' }

          def build_variables
            {}
          end
        end.new(current_user: user, params: params)
      end

      it 'raises NotImplementedError' do
        expect { tool_without_operation_name.operation_name }
          .to raise_error(NotImplementedError, 'operation_name must be defined')
      end
    end

    context 'when defined in version metadata' do
      it 'returns the operation name from metadata' do
        expect(tool.operation_name).to eq('testMutation')
      end
    end
  end

  describe '#build_variables' do
    context 'when not implemented in subclass' do
      let(:tool_without_variables) do
        Class.new(described_class) do
          register_version '1.0.0', {
            operation_name: 'test',
            graphql_operation: 'query { test }'
          }
        end.new(current_user: user, params: params)
      end

      it 'raises NotImplementedError' do
        expect { tool_without_variables.build_variables }
          .to raise_error(NotImplementedError, 'build_variables must be implemented')
      end
    end

    context 'when implemented in subclass' do
      it 'returns the variables' do
        expect(tool.build_variables).to eq({ input: { projectPath: 'gitlab-org/gitlab' } })
      end
    end
  end

  describe '#execute' do
    let(:graphql_result) do
      {
        'data' => {
          'testMutation' => {
            'result' => { 'id' => 'gid://gitlab/Test/1', 'title' => 'Test', 'description' => 'Description' },
            'errors' => []
          }
        }
      }
    end

    let(:operation_data) do
      {
        'result' => { 'id' => 'gid://gitlab/Test/1', 'title' => 'Test', 'description' => 'Description' },
        'errors' => []
      }
    end

    let(:formatted_content) do
      [{ type: 'text', text: Gitlab::Json.dump(operation_data) }]
    end

    let(:success_response) { instance_double(Mcp::Tools::Response) }

    before do
      allow(GitlabSchema).to receive(:execute).and_return(graphql_result)
      allow(::Mcp::Tools::Response).to receive(:success).and_return(success_response)
      allow(::Mcp::Tools::Response).to receive(:error)
    end

    it 'executes GraphQL mutation with correct context' do
      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: { input: { projectPath: 'gitlab-org/gitlab' } },
        context: {
          current_user: user,
          is_sessionless_user: false
        }
      )
    end

    it 'uses version-specific GraphQL operation' do
      tool.execute

      expect(GitlabSchema).to have_received(:execute) do |operation, **_options|
        expect(operation).to include('result { id title description }')
      end
    end

    it 'returns success response' do
      result = tool.execute

      expect(::Mcp::Tools::Response).to have_received(:success).with(
        formatted_content,
        operation_data
      )
      expect(result).to eq(success_response)
    end

    context 'when GraphQL returns syntax errors' do
      let(:graphql_result) do
        {
          'errors' => [
            { 'message' => 'Syntax error' }
          ]
        }
      end

      let(:error_response) { instance_double(Mcp::Tools::Response) }

      before do
        allow(::Mcp::Tools::Response).to receive(:error).and_return(error_response)
      end

      it 'returns error response' do
        result = tool.execute

        expect(::Mcp::Tools::Response).to have_received(:error).with('Syntax error')
        expect(result).to eq(error_response)
      end
    end

    context 'when mutation returns business logic errors' do
      let(:graphql_result) do
        {
          'data' => {
            'testMutation' => {
              'result' => nil,
              'errors' => ['Title cannot be blank']
            }
          }
        }
      end

      let(:error_response) { instance_double(Mcp::Tools::Response) }

      before do
        allow(::Mcp::Tools::Response).to receive(:error).and_return(error_response)
      end

      it 'returns error response with mutation errors' do
        result = tool.execute

        expect(::Mcp::Tools::Response).to have_received(:error).with('Title cannot be blank')
        expect(result).to eq(error_response)
      end
    end

    context 'when mutation returns multiple errors' do
      let(:graphql_result) do
        {
          'data' => {
            'testMutation' => {
              'result' => nil,
              'errors' => ['Title cannot be blank', 'Description is too short']
            }
          }
        }
      end

      let(:error_response) { instance_double(Mcp::Tools::Response) }

      before do
        allow(::Mcp::Tools::Response).to receive(:error).and_return(error_response)
      end

      it 'returns error response with joined errors' do
        result = tool.execute

        expect(::Mcp::Tools::Response).to have_received(:error).with('Title cannot be blank, Description is too short')
        expect(result).to eq(error_response)
      end
    end

    context 'when GraphQL returns errors with non-standard format' do
      let(:graphql_result) do
        {
          'errors' => [
            123 # Non-string, non-hash error
          ]
        }
      end

      let(:error_response) { instance_double(Mcp::Tools::Response) }

      before do
        allow(::Mcp::Tools::Response).to receive(:error).and_return(error_response)
      end

      it 'converts non-standard errors to strings' do
        result = tool.execute

        expect(::Mcp::Tools::Response).to have_received(:error).with('123')
        expect(result).to eq(error_response)
      end
    end

    context 'when operation returns no data' do
      let(:graphql_result) do
        {
          'data' => {
            'otherOperation' => {}
          }
        }
      end

      let(:error_response) { instance_double(Mcp::Tools::Response) }

      before do
        allow(::Mcp::Tools::Response).to receive(:error).and_return(error_response)
      end

      it 'returns error response' do
        result = tool.execute

        expect(::Mcp::Tools::Response).to have_received(:error).with('Operation returned no data')
        expect(result).to eq(error_response)
      end
    end

    context 'with different versions' do
      let(:tool_v1) { test_tool_class.new(current_user: user, params: params, version: '1.0.0') }
      let(:tool_v2) { test_tool_class.new(current_user: user, params: params, version: '2.0.0') }

      let(:graphql_result_v1) do
        {
          'data' => {
            'testMutation' => {
              'result' => { 'id' => 'gid://gitlab/Test/1' },
              'errors' => []
            }
          }
        }
      end

      it 'uses version-specific GraphQL operations' do
        allow(GitlabSchema).to receive(:execute).and_return(graphql_result_v1)

        tool_v1.execute

        expect(GitlabSchema).to have_received(:execute) do |operation, **_options|
          expect(operation).to include('result { id }')
          expect(operation).not_to include('title')
        end
      end

      it 'uses version-specific variable building' do
        params_v2 = { project_path: 'gitlab-org/gitlab', include_archived: true }
        tool_v2_with_params = test_tool_class.new(
          current_user: user,
          params: params_v2,
          version: '2.0.0'
        )

        allow(GitlabSchema).to receive(:execute).and_return(graphql_result)

        tool_v2_with_params.execute

        expect(GitlabSchema).to have_received(:execute).with(
          anything,
          variables: {
            input: {
              projectPath: 'gitlab-org/gitlab',
              includeArchived: true
            }
          },
          context: anything
        )
      end
    end
  end

  describe 'versioning integration' do
    it 'supports multiple versions with different operations' do
      tool_v1 = test_tool_class.new(current_user: user, params: params, version: '1.0.0')
      tool_v2 = test_tool_class.new(current_user: user, params: params, version: '2.0.0')

      operation_v1 = tool_v1.graphql_operation
      operation_v2 = tool_v2.graphql_operation

      expect(operation_v1).to include('result { id }')
      expect(operation_v1).not_to include('title')

      expect(operation_v2).to include('result { id title description }')
    end

    it 'uses latest version by default' do
      default_tool = test_tool_class.new(current_user: user, params: params)

      expect(default_tool.version).to eq('2.0.0')
      expect(default_tool.graphql_operation).to include('result { id title description }')
    end
  end
end
