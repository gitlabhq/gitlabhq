# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::CreateMergeRequestNoteService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:service) { described_class.new(name: 'create_merge_request_note') }
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
        'Add a new comment or reply to an existing discussion on a GitLab merge request as the authenticated ' \
          'user. To reply within a thread, pass the discussion_id returned by get_merge_request_notes.'
      )
    end

    it 'has readOnlyHint: false annotation' do
      expect(service.annotations[:readOnlyHint]).to be(false)
    end

    it 'has destructiveHint: false annotation' do
      expect(service.annotations[:destructiveHint]).to be(false)
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the merge request. ' \
              'Provide this, or project_id and merge_request_iid.'
          },
          project_id: {
            type: 'string',
            description: 'ID or path of the project. Required if url is not provided.'
          },
          merge_request_iid: {
            type: 'integer',
            description: 'Internal ID of the merge request. Required if url is not provided.'
          },
          body: {
            type: 'string',
            description: 'Content of the note/comment (max 1,048,576 characters). Lines that begin with "/" ' \
              'are rejected to avoid triggering quick actions such as /merge.',
            maxLength: 1_048_576
          },
          discussion_id: {
            type: 'string',
            description: 'Global ID of the discussion to reply to (format: gid://gitlab/Discussion/<id>). ' \
              'If omitted, creates a new top-level note.'
          }
        },
        required: %w[body],
        additionalProperties: false
      })
    end
  end

  describe '#execute' do
    let(:params) do
      {
        arguments: { project_id: project.id.to_s, merge_request_iid: merge_request.iid, body: 'Test comment' }
      }
    end

    it 'creates a note on the merge request', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']['body']).to eq('Test comment')
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

    context 'when the merge request does not exist' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, merge_request_iid: non_existing_record_iid, body: 'Test comment' } }
      end

      it 'returns a validation error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Merge request not found')
      end
    end

    context 'when the project does not exist' do
      let(:params) do
        { arguments: { project_id: non_existing_record_id.to_s, merge_request_iid: merge_request.iid, body: 'Test' } }
      end

      it 'returns an error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('not found or inaccessible')
      end
    end
  end
end
