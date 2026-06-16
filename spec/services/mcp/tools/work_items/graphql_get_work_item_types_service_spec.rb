# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GraphqlGetWorkItemTypesService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:service) { described_class.new(name: 'get_work_item_types') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'has a description mentioning work item types' do
      expect(service.description).to include('work item types')
    end

    it 'has readOnlyHint: true annotation' do
      expect(service.annotations[:readOnlyHint]).to be(true)
    end
  end

  describe 'input schema' do
    let(:schema) { described_class.version_metadata('0.1.0')[:input_schema] }
    let(:properties) { schema[:properties] }

    it 'defines object type schema' do
      expect(schema[:type]).to eq('object')
    end

    it 'defines url property' do
      expect(properties[:url][:type]).to eq('string')
    end

    it 'defines group_id property' do
      expect(properties[:group_id][:type]).to eq('string')
    end

    it 'defines project_id property' do
      expect(properties[:project_id][:type]).to eq('string')
    end

    it 'has no required fields (namespace resolved from any of url/group_id/project_id)' do
      expect(schema[:required]).to be_nil
    end
  end

  describe '#graphql_tool_class' do
    it 'returns GetWorkItemTypesTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::WorkItems::GetWorkItemTypesTool)
    end
  end

  describe '#perform_0_1_0' do
    let(:arguments) { { project_id: project.id.to_s } }

    it 'executes graphql tool with arguments' do
      expect(service).to receive(:execute_graphql_tool).with(arguments)

      service.send(:perform_0_1_0, arguments)
    end
  end

  describe '#perform_default' do
    let(:arguments) { { project_id: project.id.to_s } }

    it 'delegates to perform_0_1_0' do
      expect(service).to receive(:perform_0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    context 'when identifying the namespace by project_id' do
      let(:params) { { arguments: { project_id: project.id.to_s } } }

      it 'returns the project work item types' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['workItemTypes']).to be_an(Array)
        expect(result[:structuredContent]['workItemTypes']).not_to be_empty
      end
    end

    context 'when identifying the namespace by group_id' do
      let(:params) { { arguments: { group_id: group.id.to_s } } }

      it 'returns the group work item types' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['workItemTypes']).to be_an(Array)
      end
    end

    context 'when identifying the namespace by URL' do
      let(:params) { { arguments: { url: "http://localhost/#{project.full_path}" } } }

      it 'returns the project work item types' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['workItemTypes']).to be_an(Array)
      end
    end

    context 'when neither url nor namespace identifier is provided' do
      let(:params) { { arguments: {} } }

      it 'returns an error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('project_id or group_id')
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      let(:params) { { arguments: { project_id: project.id.to_s } } }

      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
