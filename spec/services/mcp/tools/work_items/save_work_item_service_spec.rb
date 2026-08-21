# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::SaveWorkItemService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, title: 'Original title') }

  let(:service) { described_class.new(name: 'save_work_item') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::Base::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'has readOnlyHint: false and destructiveHint: false annotations' do
      expect(service.annotations).to eq(readOnlyHint: false, destructiveHint: false)
    end
  end

  describe 'tool aliases' do
    it 'exposes create_work_item and update_work_item as aliases' do
      expect(described_class.tool_aliases).to eq(%w[create_work_item update_work_item])
    end

    it 'resolves the aliases through the manager', :aggregate_failures do
      manager = Mcp::Tools::Manager.new

      expect(manager.get_tool(name: 'create_work_item')).to be_a(described_class)
      expect(manager.get_tool(name: 'update_work_item')).to be_a(described_class)
    end
  end

  describe 'input schema' do
    it 'matches the expected contract' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq(
        {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'GitLab URL for the project, group, or work item. ' \
                'Provide exactly one of url, project_id, or group_id.'
            },
            group_id: {
              type: 'string',
              description: 'ID or path of the group. Required if URL and project_id are not provided.'
            },
            project_id: {
              type: 'string',
              description: 'ID or path of the project. Required if URL and group_id are not provided.'
            },
            work_item_iid: {
              type: 'integer',
              description: 'Internal ID of the work item to update. Omit to create a new work item.'
            },
            title: {
              type: 'string',
              description: 'Title. Required on create.'
            },
            type_name: {
              type: 'string',
              description: 'Work item type name, for example "Issue", "Task", "Epic". Required on create. ' \
                'Valid types depend on the namespace and license; invalid values return the list of valid ones.'
            },
            description: {
              type: 'string',
              description: 'Description in GitLab Flavored Markdown (max 1,048,576 characters).',
              maxLength: 1_048_576
            },
            assignee_ids: {
              type: 'array',
              items: { type: 'integer' },
              maxItems: 100,
              description: 'User IDs to assign to the work item.'
            },
            label_ids: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Label IDs or global IDs. Create only; on update use add_label_ids/remove_label_ids.'
            },
            add_label_ids: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Update only. Label IDs or global IDs to add.'
            },
            remove_label_ids: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Update only. Label IDs or global IDs to remove.'
            },
            confidential: {
              type: 'boolean',
              description: 'Sets the work item confidentiality.'
            },
            start_date: {
              type: 'string',
              description: 'Start date, YYYY-MM-DD.'
            },
            due_date: {
              type: 'string',
              description: 'Due date, YYYY-MM-DD.'
            },
            state: {
              type: 'string',
              enum: %w[opened closed],
              description: 'Update only. closed closes the work item, opened reopens it.'
            },
            parent_id: {
              type: 'string',
              description: 'Global ID or numeric ID of the parent work item (hierarchy).'
            },
            todo_action: {
              type: 'string',
              enum: %w[add mark_as_done],
              description: 'Update only. add adds a to-do for the current user, ' \
                'mark_as_done marks to-dos as done.'
            },
            todo_id: {
              type: 'string',
              description: 'Update only. Global ID or numeric ID of the to-do; ' \
                'omit to update all to-dos on the work item.'
            }
          },
          required: []
        }
      )
    end
  end

  describe '#execute' do
    context 'without work_item_iid' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, title: 'Created via MCP', type_name: 'Issue' } }
      end

      it 'routes to the create tool' do
        expect(Mcp::Tools::WorkItems::CreateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end

      it 'creates a work item and returns the compact payload', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent].keys).to match_array(%w[id iid type title state confidential web_url])
        expect(result[:structuredContent]['type']).to eq('Issue')
        expect(result[:structuredContent]['title']).to eq('Created via MCP')
        expect(result[:structuredContent]['state']).to eq('OPEN')
      end
    end

    context 'with work_item_iid' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, work_item_iid: work_item.iid, title: 'Updated via MCP' } }
      end

      it 'routes to the update tool' do
        expect(Mcp::Tools::WorkItems::UpdateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end

      it 'updates the work item and returns the compact payload', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['title']).to eq('Updated via MCP')
        expect(work_item.reload.title).to eq('Updated via MCP')
      end
    end

    context 'with a work item URL' do
      let(:params) do
        {
          arguments: {
            url: "https://gitlab.com/#{project.full_path}/-/work_items/#{work_item.iid}",
            title: 'Updated via URL'
          }
        }
      end

      it 'routes to the update tool' do
        expect(Mcp::Tools::WorkItems::UpdateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end
    end

    context 'with an issue URL' do
      let(:params) do
        { arguments: { url: "https://gdk.test/#{project.full_path}/-/issues/42", title: 'Updated via URL' } }
      end

      it 'routes to the update tool and fails without creating a work item', :aggregate_failures do
        expect(Mcp::Tools::WorkItems::UpdateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        result = nil

        expect { result = service.execute(request: request, params: params) }
          .not_to change { WorkItem.count }

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to eq('Validation error: Invalid work item URL format. Expected: .../-/work_items/<iid>')
      end
    end

    context 'when creating without a title' do
      let(:params) { { arguments: { project_id: project.id.to_s, type_name: 'Issue' } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Validation error: title is required when creating a work item')
      end
    end

    context 'when creating without a type name' do
      let(:params) { { arguments: { project_id: project.id.to_s, title: 'Created via MCP' } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to eq('Validation error: type_name is required when creating a work item')
      end
    end
  end
end
