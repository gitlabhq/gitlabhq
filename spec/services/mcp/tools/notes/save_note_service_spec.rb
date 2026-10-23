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
            description: 'GitLab URL of a merge request or work item, including issues and epics ' \
              '(.../-/merge_requests/<iid>, .../-/work_items/<iid>, .../-/issues/<iid>, or ' \
              '.../groups/<full_path>/-/epics/<iid>). Issue URLs are project-scoped; epic URLs are group-scoped ' \
              'and must include the groups/ prefix. ' \
              'The URL determines the target type, so no other identifier is needed'
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
          method: {
            type: 'string',
            enum: %w[create_note reply_discussion resolve_discussion],
            description: 'The write operation to perform. Defaults to create_note, or to reply_discussion ' \
              'when discussion_id is given. Fill only the parameters listed for the chosen method; ' \
              'other parameters are rejected.'
          },
          body: {
            type: 'string',
            description: 'Content of the note/comment (create_note, reply_discussion; max 1048576 characters). ' \
              'Lines beginning with "/" are rejected to avoid triggering quick actions such as /merge',
            maxLength: 1_048_576
          },
          internal: {
            type: 'boolean',
            description: 'Mark note as internal (visible only to members with at least the Reporter role)'
          },
          discussion_id: {
            type: 'string',
            description: 'Discussion to reply to (reply_discussion) or to resolve or unresolve ' \
              '(resolve_discussion). Accepts the global ID (gid://gitlab/Discussion/<id>) or the bare <id>. ' \
              'If omitted, creates a new top-level note'
          },
          resolved: {
            type: 'boolean',
            description: 'true resolves the discussion, false unresolves it (resolve_discussion)'
          }
        }
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

    context 'with method resolve_discussion on a work item' do
      let_it_be_with_reload(:discussion_note) do
        create(:discussion_note_on_issue, project: project, noteable: work_item)
      end

      let(:identification) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'resolves and unresolves the discussion', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'resolve_discussion',
            discussion_id: discussion_note.discussion_id, resolved: true) }
        )

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['method']).to eq('resolve_discussion')
        expect(result[:structuredContent]['resolved']).to be(true)
        expect(discussion_note.reload.resolved?).to be(true)

        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'resolve_discussion',
            discussion_id: discussion_note.discussion_id, resolved: false) }
        )

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['resolved']).to be(false)
        expect(discussion_note.reload.resolved?).to be(false)
      end

      it 'returns a validation error when resolved is missing' do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'resolve_discussion',
            discussion_id: discussion_note.discussion_id) }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to include('Missing required parameters for resolve_discussion: resolved')
      end
    end

    context 'when a parameter does not belong to the chosen method' do
      let(:identification) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'rejects body with resolve_discussion', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'resolve_discussion', discussion_id: 'abc',
            resolved: true, body: 'ignored') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to include("Parameters not valid for method 'resolve_discussion': body")
      end

      it 'rejects resolved with create_note', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'create_note', body: 'Hi', resolved: true) }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Parameters not valid for method 'create_note': resolved")
      end

      context 'when method is omitted and discussion_id is present' do
        let_it_be(:discussion_note) do
          create(:discussion_note_on_issue, project: project, noteable: work_item)
        end

        it 'defaults to reply_discussion and accepts internal: false', :aggregate_failures do
          result = service.execute(
            request: request,
            params: { arguments: identification.merge(discussion_id: discussion_note.discussion_id,
              body: 'A reply', internal: false) }
          )

          expect(result[:isError]).to be(false)
          expect(result[:structuredContent]['note']['body']).to eq('A reply')
          expect(result[:structuredContent]['note']['discussion']['id'])
            .to eq(discussion_note.discussion.to_global_id.to_s)
        end
      end
    end

    context 'when a required parameter is missing' do
      let(:identification) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'rejects create_note without body' do
        result = service.execute(request: request, params: { arguments: identification })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Missing required parameters for create_note: body')
      end

      it 'rejects reply_discussion without discussion_id' do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'reply_discussion', body: 'A reply') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to include('Missing required parameters for reply_discussion: discussion_id')
      end
    end

    context 'when method is not in the enum' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, work_item_iid: work_item.iid, method: 'approve', body: 'x' } }
      end

      it 'returns a validation error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Invalid method: 'approve'")
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
