# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Get a list of personal access tokens that belong to a user', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let_it_be(:group) { create(:group) }

  let_it_be(:legacy_token) { create(:personal_access_token, user: user) }
  let_it_be(:granular_token) { create(:granular_pat, permissions: ['read_member_role'], user: user, namespace: group) }

  let(:permission_source_file) { 'config/authz/permissions/member_role/read.yml' }
  let(:permission_definition) do
    {
      name: 'read_member_role',
      description: 'Grants the ability to read member roles',
      feature_category: 'system_access',
      available_for_tokens: true
    }
  end

  let(:mock_permission) { ::Authz::Permission.new(permission_definition, permission_source_file) }

  let(:fields) do
    <<~GQL
      personalAccessTokens {
        nodes {
          id
          name
          description
          granular
          revoked
          scopes {
            ... on AccessTokenLegacyScope {
              value
            }
            ... on AccessTokenGranularScope {
              access
              namespace {
                id
              }
              permissions {
                name
              }
            }
          }
          active
          lastUsedAt
          createdAt
          expiresAt
        }
      }
    GQL
  end

  let(:query) do
    graphql_query_for('user', { id: user.to_global_id.to_s }, fields)
  end

  let(:personal_access_tokens_data) { graphql_data['user']['personalAccessTokens'] }

  before do
    allow(::Authz::Permission).to receive_messages(all_for_tokens: [mock_permission])
  end

  context 'when user is authenticated' do
    let(:current_user) { user }

    it 'returns both legacy and granular personal access tokens that belong to the user' do
      post_graphql(query, current_user: current_user)

      expect(personal_access_tokens_data['nodes']).to include({
        'id' => legacy_token.to_gid.to_s,
        'name' => legacy_token.name,
        'description' => 'Token description',
        'granular' => false,
        'revoked' => false,
        'scopes' => [{ 'value' => 'api' }],
        'active' => true,
        'lastUsedAt' => nil,
        'createdAt' => legacy_token.created_at.iso8601,
        'expiresAt' => legacy_token.expires_at.iso8601
      },
        {
          'id' => granular_token.to_gid.to_s,
          'name' => granular_token.name,
          'description' => 'Token description',
          'granular' => true,
          'revoked' => false,
          'scopes' => [{
            'access' => 'PERSONAL_PROJECTS',
            'namespace' => { 'id' => group.to_gid.to_s },
            'permissions' => [{ 'name' => 'read_member_role' }]
          }],
          'active' => true,
          'lastUsedAt' => nil,
          'createdAt' => granular_token.created_at.iso8601,
          'expiresAt' => granular_token.expires_at.iso8601
        })
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      create_list(:granular_pat, 10, permissions: ['read_member_role'], user: user, namespace: create(:group))

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
    end

    describe 'scope access' do
      include Rspec::Parameterized::TableSyntax

      where(access: Authz::GranularScope.accesses.keys)

      with_them do
        before do
          granular_token.granular_scopes.first.update!(access:)
        end

        it 'sets the access' do
          post_graphql(query, current_user:)

          expect(personal_access_tokens_data['nodes']).to include(
            a_hash_including(
              'id' => granular_token.to_gid.to_s,
              'scopes' => [a_hash_including('access' => access.upcase)]
            )
          )
        end
      end
    end
  end

  context 'when current user is another user' do
    let_it_be(:current_user) { create(:user) }

    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(personal_access_tokens_data).to be_blank
    end
  end

  context 'when current user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    it 'returns the personal access tokens of the user' do
      post_graphql(query, current_user: current_user)

      expect(personal_access_tokens_data['nodes']).to include(
        a_hash_including(
          'id' => legacy_token.to_gid.to_s,
          'granular' => false
        ),
        a_hash_including(
          'id' => granular_token.to_gid.to_s,
          'granular' => true
        )
      )
    end
  end
end
