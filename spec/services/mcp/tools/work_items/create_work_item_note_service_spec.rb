# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::CreateWorkItemNoteService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
  let_it_be(:group_work_item) { create(:work_item, :epic, namespace: group, iid: 123) }

  let(:service) { described_class.new(name: 'create_workitem_note') }
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
      expect(described_class.superclass).to eq(Mcp::Tools::Base::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'has correct description' do
      expect(service.description).to eq('Create a new note (comment) on a GitLab work item')
    end

    it 'has readOnlyHint: false annotation' do
      annotations = service.annotations
      expect(annotations[:readOnlyHint]).to be(false)
    end

    it 'has destructiveHint: false annotation' do
      annotations = service.annotations
      expect(annotations[:destructiveHint]).to be(false)
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
              description: 'GitLab URL for the work item.'
            },
            group_id: {
              type: 'string',
              description: 'ID or path of the group. Required if URL and project_path are not provided.'
            },
            project_id: {
              type: 'string',
              description: 'ID or path of the project. Required if URL and group_id are not provided.'
            },
            work_item_iid: {
              type: 'integer',
              description: 'Internal ID of the work item. Required if URL is not provided.'
            },
            body: {
              type: 'string',
              description: 'Content of the note/comment (max 1,048,576 characters)',
              maxLength: 1_048_576
            },
            internal: {
              type: 'boolean',
              description: 'Mark note as internal (visible only to project members with Reporter role or higher)',
              default: false
            },
            discussion_id: {
              type: 'string',
              description: 'Global ID of the discussion to reply to (format: gid://gitlab/Discussion/<id>)'
            }
          },
          required: ['body']
        }
      )
    end
  end

  describe '#graphql_tool_class' do
    it 'returns CreateWorkItemNoteTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::WorkItems::CreateWorkItemNoteTool)
    end
  end

  describe '#perform_0_1_0' do
    let(:arguments) do
      {
        project_id: project.id.to_s,
        work_item_iid: work_item.iid,
        body: 'Test comment'
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
      expect(result[:structuredContent]['note']).to be_present
    end
  end

  describe '#perform_default' do
    let(:arguments) do
      {
        project_id: project.id.to_s,
        work_item_iid: work_item.iid,
        body: 'Test comment'
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
          work_item_iid: work_item.iid,
          body: 'Test comment'
        }
      }
    end

    it 'creates note on work item' do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']['body']).to eq('Test comment')
    end

    it 'instantiates tool with correct parameters' do
      expect(Mcp::Tools::WorkItems::CreateWorkItemNoteTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
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
