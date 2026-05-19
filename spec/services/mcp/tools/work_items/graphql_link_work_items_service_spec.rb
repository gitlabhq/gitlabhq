# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GraphqlLinkWorkItemsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group) }
  let_it_be(:source_work_item) { create(:work_item, :issue, project: project, iid: 1) }
  let_it_be(:target_work_item) { create(:work_item, :issue, project: project, iid: 2) }
  let_it_be(:group_work_item) { create(:work_item, :epic, namespace: group, iid: 10) }

  let(:service) { described_class.new(name: 'link_work_items') }
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:target_gid) { target_work_item.to_global_id.to_s }
  let(:group_work_item_gid) { group_work_item.to_global_id.to_s }

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

    it 'has correct description' do
      expect(service.description).to include('Link a work item')
    end

    it 'has readOnlyHint: false annotation' do
      expect(service.annotations[:readOnlyHint]).to be(false)
    end

    it 'has destructiveHint: false annotation' do
      expect(service.annotations[:destructiveHint]).to be(false)
    end
  end

  describe 'input schema' do
    let(:schema) { described_class.version_metadata('0.1.0')[:input_schema] }
    let(:properties) { schema[:properties] }

    it 'defines object type schema' do
      expect(schema[:type]).to eq('object')
    end

    it 'requires work_items_ids field' do
      expect(schema[:required]).to eq(['work_items_ids'])
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

    it 'defines work_item_iid property' do
      expect(properties[:work_item_iid][:type]).to eq('integer')
    end

    it 'defines work_items_ids as array with constraints' do
      expect(properties[:work_items_ids][:type]).to eq('array')
      expect(properties[:work_items_ids][:minItems]).to eq(1)
      expect(properties[:work_items_ids][:maxItems]).to eq(10)
    end

    it 'defines link_type with CE enum values only' do
      expect(properties[:link_type][:type]).to eq('string')
      expect(properties[:link_type][:enum]).to match_array(%w[relates_to])
      expect(properties[:link_type][:default]).to eq('relates_to')
    end
  end

  describe '#graphql_tool_class' do
    it 'returns LinkWorkItemsTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::WorkItems::LinkWorkItemsTool)
    end
  end

  describe '#perform_0_1_0' do
    let(:arguments) do
      {
        project_id: project.id.to_s,
        work_item_iid: source_work_item.iid,
        work_items_ids: [target_gid]
      }
    end

    it 'executes graphql tool with arguments' do
      expect(service).to receive(:execute_graphql_tool).with(arguments)

      service.send(:perform_0_1_0, arguments)
    end
  end

  describe '#perform_default' do
    let(:arguments) do
      {
        project_id: project.id.to_s,
        work_item_iid: source_work_item.iid,
        work_items_ids: [target_gid]
      }
    end

    it 'delegates to perform_0_1_0' do
      expect(service).to receive(:perform_0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    context 'when identifying source work item by project_id and iid' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: [target_gid],
            link_type: 'relates_to'
          }
        }
      end

      it 'links work items successfully' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['workItem']['iid'].to_i).to eq(source_work_item.iid)
      end
    end

    context 'when identifying source work item by URL' do
      let(:params) do
        {
          arguments: {
            url: "http://localhost/#{project.full_path}/-/work_items/#{source_work_item.iid}",
            work_items_ids: [target_gid]
          }
        }
      end

      it 'links work items successfully' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['workItem']['iid'].to_i).to eq(source_work_item.iid)
      end
    end

    context 'when link_type is omitted' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: [target_gid]
          }
        }
      end

      it 'defaults to related link type' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
      end
    end

    context 'when work_items_ids is missing' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid
          }
        }
      end

      it 'returns an error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('work_items_ids')
      end
    end

    context 'when work_items_ids contains an invalid ID format' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: ['not-a-valid-gid']
          }
        }
      end

      it 'returns an error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Invalid work item ID format')
      end
    end

    context 'when work_items_ids exceeds 10 items' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: Array.new(11) { |i| "gid://gitlab/WorkItem/#{i + 100}" }
          }
        }
      end

      it 'returns an error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('cannot contain more than 10 items')
      end
    end

    context 'when link_type is invalid' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: [target_gid],
            link_type: 'invalid_type'
          }
        }
      end

      it 'returns an error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content]
          .first[:text]).to include("Invalid link_type: 'invalid_type'. Must be one of: relates_to")
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: [target_gid]
          }
        }
      end

      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
