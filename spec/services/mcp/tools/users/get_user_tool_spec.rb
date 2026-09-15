# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Users::GetUserTool, feature_category: :mcp_server do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:params) { { username: other_user.username } }
  let(:tool) { described_class.new(current_user: current_user, params: params) }

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      expect(tool.graphql_operation).to include('query mcpGetUser')
    end
  end

  describe '#operation_name' do
    it 'is user when looking up by username' do
      expect(tool.operation_name).to eq('user')
    end

    context 'when looking up by id' do
      let(:params) { { id: other_user.id } }

      it 'is user' do
        expect(tool.operation_name).to eq('user')
      end
    end

    context 'when looking up the authenticated user' do
      let(:params) { { me: true } }

      it 'is currentUser' do
        expect(tool.operation_name).to eq('currentUser')
      end
    end
  end

  describe '#build_variables' do
    it 'builds variables from username' do
      expect(tool.build_variables).to eq(username: other_user.username)
    end

    context 'with id' do
      let(:params) { { id: other_user.id } }

      it 'builds a user global ID' do
        expect(tool.build_variables).to eq(id: "gid://gitlab/User/#{other_user.id}")
      end
    end

    context 'with me' do
      let(:params) { { me: true } }

      it 'builds the me flag' do
        expect(tool.build_variables).to eq(me: true)
      end
    end

    context 'when no identifier is provided' do
      let(:params) { {} }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide exactly one of username, id, or me')
      end
    end

    context 'when multiple identifiers are provided' do
      let(:params) { { username: other_user.username, me: true } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide exactly one of username, id, or me')
      end
    end

    context 'when me is false and no other identifier is given' do
      let(:params) { { me: false } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide exactly one of username, id, or me')
      end
    end

    context 'when me is false next to a username' do
      let(:params) { { username: other_user.username, me: false } }

      it 'ignores me and builds variables for the username' do
        expect(tool.build_variables).to eq(username: other_user.username)
      end
    end
  end

  describe '#execute' do
    context 'when looking up by username' do
      it 'executes the query as the current user' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        tool.execute

        expect(GitlabSchema).to have_received(:execute).with(
          anything,
          variables: { username: other_user.username },
          context: hash_including(current_user: current_user)
        )
      end

      it 'returns the user with a numeric id' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:content].first[:type]).to eq('text')
        expect(result[:structuredContent]).to eq(
          id: other_user.id,
          username: other_user.username,
          name: other_user.name,
          state: 'active',
          web_url: Gitlab::Routing.url_helpers.user_url(other_user)
        )
      end
    end

    context 'when looking up by id' do
      let(:params) { { id: other_user.id } }

      it 'returns the user' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(id: other_user.id, username: other_user.username)
      end
    end

    context 'when looking up the authenticated user' do
      let(:params) { { me: true } }

      it 'returns the current user' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(id: current_user.id, username: current_user.username)
      end
    end

    context 'when the user does not exist' do
      let(:params) { { username: 'this-user-does-not-exist' } }

      it 'returns a not found error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('User not found or inaccessible')
      end
    end

    context 'when looking up a nonexistent id' do
      let(:params) { { id: non_existing_record_id } }

      it 'returns a not found error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('User not found or inaccessible')
      end
    end

    context 'when the current user is not authorized to read the user' do
      let(:params) { { username: other_user.username } }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(current_user, :read_user, other_user).and_return(false)
      end

      it 'returns the same error as for a nonexistent user' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('User not found or inaccessible')
      end
    end

    context 'when looking up a blocked user' do
      let_it_be(:blocked_user) { create(:user, :blocked) }

      let(:params) { { username: blocked_user.username } }

      it 'returns the user with the blocked state' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to include(id: blocked_user.id, state: 'blocked')
      end
    end
  end
end
