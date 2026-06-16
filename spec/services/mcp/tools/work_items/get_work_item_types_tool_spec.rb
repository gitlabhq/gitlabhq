# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetWorkItemTypesTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:params) { { project_id: project.id.to_s } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_query' do
      it 'returns the GraphQL query string' do
        query = described_class.build_query

        expect(query).to include('query GetNamespaceWorkItemTypes($fullPath: ID!)')
        expect(query).to include('namespace(fullPath: $fullPath)')
        expect(query).to include('workItemTypes')
        expect(query).to include('iconName')
        expect(query).to include('widgetDefinitions')
      end
    end
  end

  describe 'versioning' do
    it 'registers version using VERSIONS constant' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('namespace')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('query GetNamespaceWorkItemTypes')
      expect(operation).to include('workItemTypes')
    end
  end

  describe '#build_variables' do
    context 'when identified by project_id' do
      it 'resolves the project full_path' do
        expect(tool.build_variables).to eq(fullPath: project.full_path)
      end
    end

    context 'when identified by group_id' do
      let(:params) { { group_id: group.id.to_s } }

      it 'resolves the group full_path' do
        expect(tool.build_variables).to eq(fullPath: group.full_path)
      end
    end

    context 'when identified by URL pointing at a project' do
      let(:params) { { url: "https://gitlab.com/#{project.full_path}" } }

      it 'resolves the project full_path' do
        expect(tool.build_variables).to eq(fullPath: project.full_path)
      end
    end

    context 'when neither project_id nor group_id provided' do
      let(:params) { {} }

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, /Must provide either project_id or group_id/)
      end
    end

    context 'when user lacks access' do
      let_it_be(:private_project) { create(:project, :private) }
      let(:params) { { project_id: private_project.id.to_s } }

      it 'raises ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end

  describe 'integration' do
    it 'executes the query and returns work item types' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      types = result[:structuredContent]['workItemTypes']
      expect(types).to be_an(Array)
      expect(types).not_to be_empty

      first_type = types.first
      expect(first_type).to include('id', 'name', 'iconName', 'widgetDefinitions')
      expect(first_type['widgetDefinitions']).to be_an(Array)
    end

    it 'includes the system-defined Issue type' do
      result = tool.execute

      type_names = result[:structuredContent]['workItemTypes'].pluck('name')
      expect(type_names).to include('Issue')
    end
  end

  describe '#process_result' do
    context 'when the GraphQL response contains errors' do
      it 'returns the error response from the parent process_result without further processing' do
        graphql_error_result = {
          'errors' => [{ 'message' => 'Something went wrong' }]
        }

        allow(GitlabSchema).to receive(:execute).and_return(graphql_error_result)

        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Something went wrong')
      end
    end

    context 'when work item types are not present in the structured content' do
      it 'returns a "not found or inaccessible" error' do
        # Simulate a response where the namespace resolves but workItemTypes is missing
        # (for example, when visibility settings disable all types for the requester).
        empty_namespace_result = {
          'data' => { 'namespace' => { 'id' => 'gid://gitlab/Group/1' } }
        }

        allow(GitlabSchema).to receive(:execute).and_return(empty_namespace_result)

        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Work item types not found or inaccessible')
      end
    end
  end
end
