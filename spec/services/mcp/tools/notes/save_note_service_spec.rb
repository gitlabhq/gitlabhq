# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Notes::SaveNoteService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }

  let(:service) { described_class.new(name: 'save_note') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'has readOnlyHint: false annotation' do
      expect(service.annotations[:readOnlyHint]).to be(false)
    end

    it 'has destructiveHint: false annotation' do
      expect(service.annotations[:destructiveHint]).to be(false)
    end

    it 'aliases the tools it replaces' do
      expect(described_class.tool_aliases)
        .to contain_exactly('create_merge_request_note', 'create_workitem_note', 'create_work_item_note')
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the merge request or work item. The URL determines the target ' \
              'type, so no other identifier is needed'
          },
          project_id: {
            type: 'string',
            description: 'ID or path of the project. Required with merge_request_iid, and with ' \
              'work_item_iid for project-level work items'
          },
          group_id: {
            type: 'string',
            description: 'ID or path of the group. Required with work_item_iid for group-level work items'
          },
          merge_request_iid: {
            type: 'integer',
            description: 'Internal ID of the merge request. Provide with project_id. Mutually exclusive ' \
              'with work_item_iid'
          },
          work_item_iid: {
            type: 'integer',
            description: 'Internal ID of the work item. Provide with project_id or group_id. Mutually ' \
              'exclusive with merge_request_iid'
          },
          body: {
            type: 'string',
            description: 'Content of the note/comment (max 1,048,576 characters). Lines beginning with ' \
              '"/" are rejected to avoid triggering quick actions such as /merge',
            maxLength: 1_048_576
          },
          internal: {
            type: 'boolean',
            description: 'Mark note as internal (visible only to members with at least the Reporter role)',
            default: false
          },
          discussion_id: {
            type: 'string',
            description: 'Global ID of the discussion to reply to (format: gid://gitlab/Discussion/<id>). ' \
              'If omitted, creates a new top-level note'
          }
        },
        required: %w[body]
      })
    end
  end

  describe '#execute' do
    context 'with a merge request target' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, merge_request_iid: merge_request.iid, body: 'Test comment' } }
      end

      it 'creates a note on the merge request', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['note']['body']).to eq('Test comment')
      end
    end

    context 'with a work item target' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, work_item_iid: work_item.iid, body: 'Test comment' } }
      end

      it 'creates a note on the work item', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['note']['body']).to eq('Test comment')
      end
    end

    context 'when current_user is not set' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, merge_request_iid: merge_request.iid, body: 'Test comment' } }
      end

      before do
        service.set_cred(current_user: nil)
      end

      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end

    context 'when the merge request does not exist' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, merge_request_iid: non_existing_record_iid, body: 'Test' } }
      end

      it 'returns a validation error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Merge request not found')
      end
    end

    context 'when the project does not exist' do
      let(:params) do
        { arguments: { project_id: 'does/not/exist', merge_request_iid: merge_request.iid, body: 'Test' } }
      end

      it 'returns an error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Merge request not found')
      end
    end
  end
end
