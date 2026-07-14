# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::GetMergeRequestNotesService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:note) { create(:note_on_merge_request, noteable: merge_request, project: project, author: user) }

  let(:service) { described_class.new(name: 'get_merge_request_notes') }

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

    it 'has correct description' do
      expect(service.description).to eq(
        'Get the notes (comments and system notes) for a specific merge request.'
      )
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        required: [],
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
          after: {
            type: 'string',
            description: 'Cursor for forward pagination. Use endCursor from previous response.'
          },
          before: {
            type: 'string',
            description: 'Cursor for backward pagination. Use startCursor from previous response.'
          },
          first: {
            type: 'integer',
            description: 'Number of notes to return after the cursor (forward pagination, max 100)',
            minimum: 1,
            maximum: 100
          },
          last: {
            type: 'integer',
            description: 'Number of notes to return before the cursor (backward pagination, max 100)',
            minimum: 1,
            maximum: 100
          }
        }
      })
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) do
      { arguments: { project_id: project.id.to_s, merge_request_iid: merge_request.iid } }
    end

    it 'retrieves the notes connection and resolution counts from the merge request', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to have_key('resolvedDiscussionsCount')
      expect(result[:structuredContent]).to have_key('resolvableDiscussionsCount')
      expect(result[:structuredContent]['notes']).to have_key('nodes')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::MergeRequests::GetMergeRequestNotesTool).to receive(:new).with(
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
            merge_request_iid: merge_request.iid,
            first: 10,
            after: 'cursor1'
          }
        }
      end

      it 'passes pagination parameters to the tool' do
        expect(Mcp::Tools::MergeRequests::GetMergeRequestNotesTool).to receive(:new).with(
          current_user: user,
          params: hash_including(first: 10, after: 'cursor1'),
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
