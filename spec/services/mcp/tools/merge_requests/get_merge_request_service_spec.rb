# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::GetMergeRequestService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:service) { described_class.new(name: 'get_merge_request') }

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

    it 'is read-only' do
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:description]).to eq(
        'Get a merge request and optionally its diffs, commits, notes, pipelines, or discussions. ' \
          'By default only the base merge request metadata is returned; request associated data through the ' \
          '`include` parameter so nothing extra is fetched unless asked for.'
      )

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
          include: {
            type: 'array',
            description: 'Associated facets to fetch inline, one per call. diffs returns aggregate change ' \
              'stats and a per-file breakdown by default; set detail=full_patch for raw per-file patch ' \
              'text or detail=none for summary counts only. For conflicts use the ' \
              'get_merge_request_conflicts tool. notes supports pagination (notes_after/notes_first).',
            items: {
              type: 'string',
              enum: %w[diffs commits notes pipelines discussions]
            },
            maxItems: 1
          },
          detail: {
            type: 'string',
            description: 'Level of diff detail, applies only when diffs is in include. ' \
              'none: summary counts only; stats: per-file additions and deletions (default); ' \
              'full_patch: per-file patch text (raw diff), plus the per-file stats.',
            enum: %w[none stats full_patch]
          },
          diffs_after: {
            type: 'string',
            description: 'Cursor for forward pagination of files. ' \
              'Use pageInfo.endCursor from a previous response. ' \
              'Applies only when diffs is in include and detail is full_patch.'
          },
          diffs_first: {
            type: 'integer',
            description: 'Number of files to return after the cursor (forward pagination). Max 100. ' \
              'Applies only when diffs is in include and detail is full_patch.',
            minimum: 1,
            maximum: 100
          },
          notes_after: {
            type: 'string',
            description: 'Cursor for forward pagination of notes. ' \
              'Use pageInfo.endCursor from a previous response. Applies only when notes is in include.'
          },
          notes_first: {
            type: 'integer',
            description: 'Number of notes to return after the cursor (forward pagination). Max 100. ' \
              'Applies only when notes is in include.',
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

    it 'retrieves the base merge request metadata', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to include('iid' => merge_request.iid.to_s)
      expect(result[:structuredContent]).to have_key('title')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::MergeRequests::GetMergeRequestTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'when include is sent as nil, an empty string, or an empty array' do
      it 'treats it as omitted and returns the base merge request', :aggregate_failures do
        [nil, '', []].each do |value|
          arguments = params[:arguments].merge(include: value)
          result = service.execute(request: request, params: { arguments: arguments })

          expect(result[:isError]).to be(false)
          expect(result[:structuredContent]).not_to have_key('commits')
        end
      end
    end

    context 'when include requests more than one facet' do
      it 'returns a validation error naming the limit', :aggregate_failures do
        arguments = params[:arguments].merge(include: %w[notes commits])
        result = service.execute(request: request, params: { arguments: arguments })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('include cannot contain more than 1 items')
      end
    end

    context 'when include contains an unknown facet' do
      it 'returns a validation error listing the valid facets', :aggregate_failures do
        arguments = params[:arguments].merge(include: ['nope'])
        result = service.execute(request: request, params: { arguments: arguments })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('diffs, commits, notes, pipelines, discussions')
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
