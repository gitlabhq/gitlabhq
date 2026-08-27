# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::ListMergeRequestsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:service) { described_class.new(name: 'list_merge_requests') }

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

    it 'is marked read-only' do
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end

    it 'locks the description' do
      expect(described_class.version_metadata('0.1.0')[:description]).to eq(
        'List or search merge requests in a GitLab project by author, assignee, reviewer, ' \
          'state, milestone, labels, or text. Identify the project with exactly one of url or ' \
          'project_id. Returns compact merge request metadata; use get_merge_request for the full ' \
          'detail of a single merge request, or search for full-text search across resource types.'
      )
    end

    it 'keeps the tool it replaces working through an alias' do
      expect(described_class.tool_aliases).to contain_exactly('gitlab_merge_request_search')
    end

    it 'is resolvable by its alias through the manager' do
      expect(Mcp::Tools::Manager.new.get_tool(name: 'gitlab_merge_request_search')).to be_a(described_class)
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
            description: 'GitLab URL of the project.'
          },
          project_id: {
            type: 'string',
            description: 'ID or full path of the project.'
          },
          author_username: {
            type: 'string',
            description: 'Filter by the username of the merge request author.'
          },
          assignee_username: {
            type: 'string',
            description: 'Filter by the username of an assignee.'
          },
          reviewer_username: {
            type: 'string',
            description: 'Filter by the username of a reviewer.'
          },
          state: {
            type: 'string',
            description: 'Filter by merge request state. Omit to include merge requests in any state.',
            enum: %w[opened closed merged locked all]
          },
          scope: {
            type: 'string',
            description: 'Filter relative to the authenticated user, for requests such as ' \
              '"my merge requests" or "merge requests awaiting my review". ' \
              'created_by_me sets author_username, assigned_to_me sets assignee_username, ' \
              'review_requested sets reviewer_username. ' \
              'An explicit username wins for that field.',
            enum: %w[created_by_me assigned_to_me review_requested]
          },
          milestone: {
            type: 'string',
            description: 'Filter by the title of the milestone.'
          },
          labels: {
            type: 'string',
            description: 'Comma-separated list of label names. Only merge requests with all of ' \
              'these labels are returned.'
          },
          search: {
            type: 'string',
            description: 'Search query matched against merge request title and description.'
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination of merge requests. ' \
              'Use pageInfo.endCursor from a previous response.'
          },
          first: {
            type: 'integer',
            description: 'Number of merge requests to return after the cursor (forward pagination). ' \
              'Default 20, max 100.',
            minimum: 1,
            maximum: 100
          }
        }
      })
    end
  end

  describe 'schema validation' do
    it 'rejects unknown arguments' do
      expect(service.input_schema[:additionalProperties]).to be(false)
    end

    it 'rejects numeric user ID filters, which the GraphQL connection cannot use' do
      result = service.execute(
        request: nil, params: { arguments: { project_id: project.id.to_s, author_id: user.id } }
      )

      expect(result[:content].first[:text]).to include('Validation error')
    end

    it 'accepts the comma-separated labels string the replaced tool used' do
      result = service.execute(
        request: nil, params: { arguments: { project_id: project.id.to_s, labels: 'bug,urgent' } }
      )

      expect(result[:isError]).to be(false)
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: { project_id: project.id.to_s } } }

    it 'returns the merge requests connection', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result[:structuredContent]).to have_key('pageInfo')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::MergeRequests::ListMergeRequestsTool).to receive(:new).with(
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

      it 'returns an error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
