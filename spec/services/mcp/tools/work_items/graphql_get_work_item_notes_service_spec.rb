# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GraphqlGetWorkItemNotesService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
  let_it_be(:note) { create(:note, noteable: work_item, project: project, author: user, note: 'Test comment') }

  let(:service) { described_class.new(name: 'get_workitem_notes') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    project.add_developer(user)
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

    it 'has correct description' do
      expect(service.description).to eq('Get all comments (notes) for a specific work item')
    end
  end

  describe 'input schema' do
    let(:schema) { described_class.version_metadata('0.1.0')[:input_schema] }

    it 'defines object type schema' do
      expect(schema[:type]).to eq('object')
    end

    it 'does not require any fields' do
      expect(schema[:required]).to be_nil
    end

    context 'with work item identification properties' do
      let(:properties) { schema[:properties] }

      where(:property_name, :property_type, :description_includes) do
        [
          [:url, 'string', 'GitLab URL for the work item'],
          [:group_id, 'string', 'ID or path of the group'],
          [:project_id, 'string', 'ID or path of the project'],
          [:work_item_iid, 'integer', 'Internal ID of the work item']
        ]
      end

      with_them do
        it 'defines property with correct type and description' do
          expect(properties[property_name][:type]).to eq(property_type)
          expect(properties[property_name][:description]).to include(description_includes)
        end
      end
    end

    context 'with pagination properties' do
      let(:properties) { schema[:properties] }

      it 'defines after cursor' do
        expect(properties[:after][:type]).to eq('string')
        expect(properties[:after][:description]).to include('forward pagination')
      end

      it 'defines before cursor' do
        expect(properties[:before][:type]).to eq('string')
        expect(properties[:before][:description]).to include('backward pagination')
      end

      it 'defines first with constraints' do
        expect(properties[:first][:type]).to eq('integer')
        expect(properties[:first][:minimum]).to eq(1)
        expect(properties[:first][:maximum]).to eq(100)
        expect(properties[:first][:description]).to include('forward pagination')
      end

      it 'defines last with constraints' do
        expect(properties[:last][:type]).to eq('integer')
        expect(properties[:last][:minimum]).to eq(1)
        expect(properties[:last][:maximum]).to eq(100)
        expect(properties[:last][:description]).to include('backward pagination')
      end
    end
  end

  describe '#graphql_tool_class' do
    it 'returns GetWorkItemNotesTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::WorkItems::GetWorkItemNotesTool)
    end
  end

  describe '#perform_0_1_0' do
    let(:arguments) do
      {
        project_id: project.id.to_s,
        work_item_iid: work_item.iid
      }
    end

    it 'executes graphql tool with arguments' do
      expect(service).to receive(:execute_graphql_tool).with(arguments)

      service.send(:perform_0_1_0, arguments)
    end

    it 'returns result from graphql tool' do
      result = service.send(:perform_0_1_0, arguments)

      expect(result).to be_a(Hash)
      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['nodes']).to be_present
    end
  end

  describe '#perform_default' do
    let(:arguments) do
      {
        project_id: project.id.to_s,
        work_item_iid: work_item.iid
      }
    end

    it 'delegates to perform_0_1_0' do
      expect(service).to receive(:perform_0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    let(:params) do
      {
        arguments: {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid
        }
      }
    end

    it 'retrieves notes from work item' do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['nodes']).to be_present
    end

    it 'instantiates tool with correct parameters' do
      expect(Mcp::Tools::WorkItems::GetWorkItemNotesTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'with pagination parameters' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: work_item.iid,
            first: 10,
            after: 'cursor123'
          }
        }
      end

      it 'passes pagination parameters to tool' do
        expect(Mcp::Tools::WorkItems::GetWorkItemNotesTool).to receive(:new).with(
          current_user: user,
          params: hash_including(
            first: 10,
            after: 'cursor123'
          ),
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
