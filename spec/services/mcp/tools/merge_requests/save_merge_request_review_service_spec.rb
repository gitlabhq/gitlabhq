# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::SaveMergeRequestReviewService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:service) { described_class.new(name: 'save_merge_request_review') }
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

    it 'has correct description' do
      expect(service.description).to eq(
        'Write merge request review artifacts as the authenticated user. ' \
          'Exactly one method per call: create_note adds a top-level comment; reply_discussion ' \
          'replies within an existing discussion; create_diff_note comments on a specific diff line; ' \
          'resolve_discussion resolves or unresolves a discussion; submit_review posts multiple diff ' \
          'comments plus an optional summary in one call; post_duo_review asks GitLab Duo to review ' \
          'the merge request. Identify the merge request by url, or by project_id and ' \
          'merge_request_iid. Each parameter below names the methods that use it.'
      )
    end

    it 'has write, non-destructive annotations' do
      expect(service.annotations).to eq(readOnlyHint: false, destructiveHint: false)
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the merge request. Provide this, or project_id and merge_request_iid.'
          },
          project_id: {
            type: 'string',
            description: 'ID or path of the project. Required if url is not provided.'
          },
          merge_request_iid: {
            type: 'integer',
            description: 'Internal ID of the merge request. Required if url is not provided.'
          },
          method: {
            type: 'string',
            enum: %w[create_note reply_discussion create_diff_note resolve_discussion
              submit_review post_duo_review],
            description: 'The write operation to perform. Fill only the parameters listed for the ' \
              'chosen method; other parameters are rejected.'
          },
          body: {
            type: 'string',
            description: 'Note text (create_note, reply_discussion, create_diff_note; max 1,048,576 ' \
              'characters). Lines that begin with "/" are rejected to avoid triggering quick actions ' \
              'such as /merge.',
            maxLength: 1_048_576
          },
          discussion_id: {
            type: 'string',
            description: 'Discussion to act on (reply_discussion, resolve_discussion). Accepts the ' \
              'global ID (gid://gitlab/Discussion/<id>) or the bare <id> returned by ' \
              'get_merge_request with include: ["discussions"].'
          },
          internal: {
            type: 'boolean',
            description: 'Mark the note as internal, visible only to users who can see internal ' \
              'notes (create_note). Default is false.'
          },
          resolved: {
            type: 'boolean',
            description: 'true resolves the discussion, false unresolves it (resolve_discussion).'
          },
          old_path: {
            type: 'string',
            description: 'File path before the change (create_diff_note). Provide old_path and/or ' \
              'new_path; for a file that was not renamed, use the same path for both.'
          },
          new_path: {
            type: 'string',
            description: 'File path after the change (create_diff_note).'
          },
          old_line: {
            type: 'integer',
            description: 'Line number in the old version of the file (create_diff_note). Use for ' \
              'deleted or unchanged lines. Provide old_line and/or new_line.'
          },
          new_line: {
            type: 'integer',
            description: 'Line number in the new version of the file (create_diff_note). Use for ' \
              'added or unchanged lines.'
          },
          comments: {
            type: 'array',
            description: 'Diff comments to post (submit_review; 1-20 entries). ' \
              'Each entry becomes one diff note.',
            maxItems: 20,
            items: {
              type: 'object',
              properties: {
                file: {
                  type: 'string',
                  description: 'Path of the file to comment on, as it appears after the change. ' \
                    'For a file renamed in the diff, use the create_diff_note method with ' \
                    'old_path and new_path instead.'
                },
                old_line: {
                  type: 'integer',
                  description: 'Line number in the old version of the file. Provide old_line and/or new_line.'
                },
                new_line: {
                  type: 'integer',
                  description: 'Line number in the new version of the file.'
                },
                body: {
                  type: 'string',
                  description: 'Comment text for this line.'
                },
                suggestion: {
                  type: 'string',
                  description: 'Replacement code for the commented line, appended to the comment as ' \
                    'a suggestion block the author can apply with one click.'
                }
              },
              required: %w[file body],
              additionalProperties: false
            }
          },
          verdict: {
            type: 'string',
            description: 'Overall review verdict, prefixed to the summary note (submit_review).'
          },
          summary: {
            type: 'string',
            description: 'Summary note posted after the diff comments (submit_review). When both ' \
              'summary and verdict are omitted, only the diff comments are posted.'
          },
          summary_internal: {
            type: 'boolean',
            description: 'Mark the summary note as internal (submit_review). Default is false.'
          }
        },
        required: %w[method]
      })
    end
  end

  describe '#execute' do
    let(:identification) { { project_id: project.id.to_s, merge_request_iid: merge_request.iid } }

    context 'with method create_note' do
      let(:params) { { arguments: identification.merge(method: 'create_note', body: 'A top-level note') } }

      it 'creates a note and returns a compact reference', :aggregate_failures do
        expect { service.execute(request: request, params: params) }.to change { merge_request.notes.count }.by(1)

        result = service.execute(request: request, params: params.deep_merge(arguments: { body: 'Another note' }))

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['method']).to eq('create_note')
        expect(result[:structuredContent]['note_id']).to eq(merge_request.notes.last.id)
        expect(result[:structuredContent]['web_url']).to include("note_#{merge_request.notes.last.id}")
      end

      it 'rejects parameters belonging to another method' do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'create_note', body: 'x', discussion_id: 'abc') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Parameters not valid for method 'create_note': discussion_id")
      end

      it 'rejects a missing required parameter' do
        result = service.execute(request: request, params: { arguments: identification.merge(method: 'create_note') })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Missing required parameters for create_note: body')
      end
    end

    context 'with method reply_discussion' do
      let_it_be(:existing_note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }

      let(:params) do
        {
          arguments: identification.merge(
            method: 'reply_discussion',
            discussion_id: existing_note.discussion_id,
            body: 'A threaded reply'
          )
        }
      end

      it 'adds the reply to the existing discussion', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['method']).to eq('reply_discussion')

        reply = ::Note.find(result[:structuredContent]['note_id'])
        expect(reply.discussion_id).to eq(existing_note.discussion_id)
      end
    end

    context 'with method resolve_discussion' do
      let_it_be(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }

      it 'resolves and unresolves the discussion', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'resolve_discussion',
            discussion_id: diff_note.discussion_id, resolved: true) }
        )

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['resolved']).to be(true)
        expect(diff_note.reload.resolved?).to be(true)

        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'resolve_discussion',
            discussion_id: diff_note.discussion_id, resolved: false) }
        )

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['resolved']).to be(false)
        expect(diff_note.reload.resolved?).to be(false)
      end
    end

    context 'with method create_diff_note' do
      let(:params) do
        {
          arguments: identification.merge(
            method: 'create_diff_note',
            body: 'Inline comment',
            old_path: 'files/ruby/popen.rb',
            new_path: 'files/ruby/popen.rb',
            new_line: 14
          )
        }
      end

      it 'creates a diff note anchored to the line', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['method']).to eq('create_diff_note')

        note = ::Note.find(result[:structuredContent]['note_id'])
        expect(note).to be_a(DiffNote)
        expect(note.position.new_line).to eq(14)
      end
    end

    context 'with method submit_review' do
      let(:comments) do
        [
          { file: 'files/ruby/popen.rb', new_line: 14, body: 'First finding' },
          { file: 'files/ruby/popen.rb', new_line: 9, body: 'Second finding', suggestion: 'improved_code' }
        ]
      end

      let(:params) do
        {
          arguments: identification.merge(
            method: 'submit_review',
            comments: comments,
            verdict: 'Needs changes',
            summary: 'Two findings to address.'
          )
        }
      end

      it 'posts every diff comment plus the summary note', :aggregate_failures do
        expect { service.execute(request: request, params: params) }.to change { merge_request.notes.count }.by(3)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['method']).to eq('submit_review')
        expect(result[:structuredContent]['comments_created']).to eq(2)
        expect(result[:structuredContent]['notes'].length).to eq(2)
        expect(result[:structuredContent]['summary']).to be_present

        summary_note = ::Note.find(result[:structuredContent].dig('summary', 'note_id'))
        expect(summary_note.note).to include('**Review verdict:** Needs changes')
        expect(summary_note.note).to include('Two findings to address.')

        suggestion_note = ::Note.find(result[:structuredContent]['notes'].last['note_id'])
        expect(suggestion_note.note).to include("```suggestion:-0+0\nimproved_code\n```")
      end

      it 'fails fast and names the already-created notes when a comment cannot be posted' do
        failing_comments = [
          { file: 'files/ruby/popen.rb', new_line: 14, body: 'Valid finding' },
          { file: 'does/not/exist.rb', new_line: 1, body: 'Invalid target' }
        ]

        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'submit_review', comments: failing_comments) }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('submit_review failed at comments[1]')
      end

      it 'creates no notes when a later comment body contains a quick action', :aggregate_failures do
        quick_action_params = {
          arguments: identification.merge(
            method: 'submit_review',
            comments: comments + [{ file: 'files/ruby/popen.rb', new_line: 4, body: '/path/to/x should change' }]
          )
        }

        expect { service.execute(request: request, params: quick_action_params) }
          .not_to change { merge_request.notes.count }

        result = service.execute(request: request, params: quick_action_params)
        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include(
          'Validation error: Quick actions (commands starting with /) are not allowed in comments[2] body'
        )
      end

      it 'creates no notes when a later comment lacks both old_line and new_line', :aggregate_failures do
        missing_line_params = {
          arguments: identification.merge(
            method: 'submit_review',
            comments: comments + [{ file: 'files/ruby/popen.rb', body: 'No line anchor' }]
          )
        }

        expect { service.execute(request: request, params: missing_line_params) }
          .not_to change { merge_request.notes.count }

        result = service.execute(request: request, params: missing_line_params)
        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include(
          'Validation error: comments[2]: Provide old_line and/or new_line'
        )
      end

      it 'names the created notes when posting a comment raises after pre-validation', :aggregate_failures do
        allow(service).to receive(:execute_graphql_tool).and_wrap_original do |original, args|
          raise ArgumentError, 'unforeseen failure' if args[:new_line] == 9

          original.call(args)
        end

        result = nil
        expect { result = service.execute(request: request, params: params) }
          .to change { merge_request.notes.count }.by(1)

        first_note_id = merge_request.notes.last.id
        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('submit_review failed at comments[1]: unforeseen failure')
        expect(result[:content].first[:text]).to include("Notes already created (not rolled back): #{first_note_id}")
        expect(result.dig(:structuredContent, :error, 'created_notes').first['note_id']).to eq(first_note_id)
      end

      it 'rejects an empty comments array' do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'submit_review', comments: []) }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('comments must contain at least one entry')
      end

      it 'resolves the merge request once for the whole fan-out', :aggregate_failures do
        allow(::MergeRequestsFinder).to receive(:new).and_call_original

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(::MergeRequestsFinder).to have_received(:new).once
      end

      it 'fails before posting anything when the diff is not ready', :aggregate_failures do
        allow_next_found_instance_of(::MergeRequest) do |instance|
          allow(instance).to receive(:has_complete_diff_refs?).and_return(false)
        end

        expect { service.execute(request: request, params: params) }
          .not_to change { merge_request.notes.count }

        result = service.execute(request: request, params: params)
        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('diff is not ready')
      end
    end

    context 'with method post_duo_review' do
      it 'is unavailable', unless: Gitlab.ee? do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'post_duo_review') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('requires GitLab Duo Code Review')
      end
    end

    context 'with an unknown method' do
      it 'is rejected by the schema enum' do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'delete_everything') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Validation error')
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns error response' do
        result = service.execute(
          request: request,
          params: { arguments: identification.merge(method: 'create_note', body: 'x') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
