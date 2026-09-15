# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Users::GetUserService, feature_category: :mcp_server do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:service) { described_class.new(name: 'get_user') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before do
    service.set_cred(current_user: current_user)
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
        'Get a single GitLab user. Use me: true to look up the authenticated user, for example ' \
          'to find your own user id before setting assignee_ids or reviewer_ids. Provide exactly one of ' \
          'username, id, or me. Returns the numeric id, username, name, state, and web URL.'
      )
    end
  end

  describe 'input schema' do
    it 'matches the expected contract' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq(
        {
          type: 'object',
          required: [],
          properties: {
            username: {
              type: 'string',
              description: 'Username of the user to look up.'
            },
            id: {
              type: 'integer',
              description: 'Numeric ID of the user to look up.'
            },
            me: {
              type: 'boolean',
              description: 'Set to true to look up the authenticated user. Omit username and id when set. ' \
                'false behaves as if me was omitted.'
            }
          }
        }
      )
    end

    it 'rejects additional properties' do
      expect(service.input_schema[:additionalProperties]).to be(false)
    end
  end

  describe '#graphql_tool_class' do
    it 'returns GetUserTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::Users::GetUserTool)
    end
  end

  describe '#execute' do
    let(:params) { { arguments: { username: other_user.username } } }

    it 'instantiates the tool with correct parameters' do
      expect(Mcp::Tools::Users::GetUserTool).to receive(:new).with(
        current_user: current_user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    it 'resolves a user by username' do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to include(id: other_user.id, username: other_user.username)
    end

    context 'with id' do
      let(:params) { { arguments: { id: other_user.id } } }

      it 'resolves a user by id' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(id: other_user.id, username: other_user.username)
      end
    end

    context 'with me' do
      let(:params) { { arguments: { me: true } } }

      it 'resolves the authenticated user' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(id: current_user.id, username: current_user.username)
      end
    end

    context 'when no identifier is provided' do
      let(:params) { { arguments: {} } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Validation error: Provide exactly one of username, id, or me')
      end
    end

    context 'when multiple identifiers are provided' do
      let(:params) { { arguments: { username: other_user.username, id: other_user.id } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Validation error: Provide exactly one of username, id, or me')
      end
    end

    context 'when me is false and no other identifier is given' do
      let(:params) { { arguments: { me: false } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Validation error: Provide exactly one of username, id, or me')
      end
    end

    context 'when me is false next to a username' do
      let(:params) { { arguments: { username: other_user.username, me: false } } }

      it 'treats me as omitted and resolves the username' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(id: other_user.id, username: other_user.username)
      end
    end

    context 'with an unknown argument' do
      let(:params) { { arguments: { username: other_user.username, unknown: 'value' } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Validation error')
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
