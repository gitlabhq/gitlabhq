# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Projects::ListProjectsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(name: 'list_projects') }

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
        'List GitLab projects. Without group_id, defaults to projects you have at least ' \
          'guest access to; pass min_access_level to raise the threshold. With group_id, lists every ' \
          'project in that group and its subgroups regardless of access level; adding min_access_level ' \
          'or visibility narrows the listing to that group only, not its subgroups. When group_id is ' \
          'given, the response includes subgroupsIncluded so you know which case applied.'
      )
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        required: [],
        properties: {
          group_id: {
            type: 'string',
            description: 'ID or full path of a group.'
          },
          min_access_level: {
            type: 'string',
            description: 'Minimum access level a project must grant you to be included.',
            enum: %w[guest planner reporter developer maintainer owner]
          },
          search: {
            type: 'string',
            description: 'Search projects by name, path, or description.'
          },
          visibility: {
            type: 'string',
            description: 'Filter by visibility level.',
            enum: ::Gitlab::VisibilityLevel.string_options.keys
          },
          archived: {
            type: 'string',
            description: 'Filter by archived state: only returns archived projects, include ' \
              'returns both, exclude returns only non-archived projects (default).',
            enum: %w[only include exclude]
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination of projects. ' \
              'Use pageInfo.endCursor from a previous response.'
          },
          first: {
            type: 'integer',
            description: 'Number of projects to return after the cursor (forward pagination). ' \
              'Max 100.',
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

    it 'rejects an invalid visibility value' do
      result = service.execute(request: nil, params: { arguments: { visibility: 'bogus' } })

      expect(result[:content].first[:text]).to include('Validation error')
    end

    it 'rejects an invalid archived value' do
      result = service.execute(request: nil, params: { arguments: { archived: 'bogus' } })

      expect(result[:content].first[:text]).to include('Validation error')
    end

    it 'rejects an invalid min_access_level value' do
      result = service.execute(request: nil, params: { arguments: { min_access_level: 'bogus' } })

      expect(result[:content].first[:text]).to include('Validation error')
    end

    it 'rejects a first value below the minimum' do
      result = service.execute(request: nil, params: { arguments: { first: 0 } })

      expect(result[:content].first[:text]).to include('Validation error')
    end

    it 'rejects a first value above the maximum' do
      result = service.execute(request: nil, params: { arguments: { first: 101 } })

      expect(result[:content].first[:text]).to include('Validation error')
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: {} } }

    it 'returns the projects connection', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result[:structuredContent]).to have_key('pageInfo')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Projects::ListProjectsTool).to receive(:new).with(
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
