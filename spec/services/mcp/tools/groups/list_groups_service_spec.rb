# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Groups::ListGroupsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(name: 'list_groups') }

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
        'List GitLab groups. Without group_id, lists top-level groups where you ' \
          'are a member. With group_id, lists the direct subgroups of that group, regardless ' \
          'of membership. Set include_subgroups to true to recurse into all descendant ' \
          'subgroups (with no group_id, this lists your groups at any depth). Archived ' \
          'groups and groups pending deletion are excluded. Useful for discovering group ' \
          'IDs and full paths for other tools.'
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
            description: 'ID or full path of a parent group to list subgroups of. ' \
              'Omit to list top-level groups where you are a member.'
          },
          search: {
            type: 'string',
            description: 'Search groups by name or full path.'
          },
          visibility: {
            type: 'string',
            description: 'Filter by visibility level.',
            enum: ::Gitlab::VisibilityLevel.string_options.keys
          },
          include_subgroups: {
            type: 'boolean',
            description: 'Include all descendant subgroups recursively instead of direct ' \
              'children only.'
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination of groups. ' \
              'Use pageInfo.endCursor from a previous response.'
          },
          first: {
            type: 'integer',
            description: 'Number of groups to return after the cursor (forward pagination). ' \
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

    it 'rejects an invalid visibility value' do
      result = service.execute(request: nil, params: { arguments: { visibility: 'bogus' } })

      expect(result[:content].first[:text]).to include('Validation error')
    end

    it 'rejects a non-boolean include_subgroups value' do
      result = service.execute(request: nil, params: { arguments: { include_subgroups: 'yes' } })

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

    it 'returns the groups connection', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result[:structuredContent]).to have_key('pageInfo')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Groups::ListGroupsTool).to receive(:new).with(
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
