# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Get a list of personal access tokens that belong to a user', feature_category: :permissions do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let_it_be(:legacy_token) do
    create(:personal_access_token, user: user, created_at: 5.days.ago,
      expires_at: 60.days.from_now)
  end

  let_it_be(:legacy_token_revoked) { create(:personal_access_token, :revoked, user: user, name: 'Revoked token') }
  let_it_be(:legacy_token_expired) { create(:personal_access_token, :expired, :with_last_used_ips, user:) }
  let_it_be(:granular_token) do
    create(:granular_pat, name: 'Special token', last_used_at: 1.day.ago, permissions: ['read_member_role'],
      user: user, namespace: group)
  end

  let(:fields) do
    <<~GQL
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
        lastUsedIps
        lastUsedAt
        createdAt
        expiresAt
      }
    GQL
  end

  let(:args) { {} }

  let(:query) do
    graphql_query_for(:user, { id: user.to_global_id.to_s },
      query_graphql_field(:personal_access_tokens, attributes_to_graphql(args).to_s, fields)
    )
  end

  let(:personal_access_tokens_data) { graphql_data_at(*%i[user personalAccessTokens nodes]) }

  subject(:send_query) do
    post_graphql(query, current_user: current_user, token: { personal_access_token: legacy_token })

    legacy_token.reload # to load last_used_at
  end

  context 'when user is authenticated' do
    let(:current_user) { user }

    it 'returns both legacy and granular personal access tokens that belong to the user' do
      send_query

      expect(personal_access_tokens_data).to include(
        {
          'id' => legacy_token.to_gid.to_s,
          'name' => legacy_token.name,
          'description' => 'Token description',
          'granular' => false,
          'revoked' => false,
          'scopes' => [{ 'value' => 'api' }],
          'active' => true,
          'lastUsedIps' => [],
          'lastUsedAt' => legacy_token.last_used_at.iso8601,
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
          'lastUsedIps' => [],
          'lastUsedAt' => granular_token.last_used_at.iso8601,
          'createdAt' => granular_token.created_at.iso8601,
          'expiresAt' => granular_token.expires_at.iso8601
        },
        a_hash_including({
          'name' => legacy_token_revoked.name,
          'revoked' => true,
          'active' => false
        }),
        a_hash_including({
          'name' => legacy_token_expired.name,
          'active' => false,
          'lastUsedIps' => legacy_token_expired.last_used_ips.map(&:ip_address)
        })
      )
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
          send_query

          expect(personal_access_tokens_data).to include(
            a_hash_including(
              'id' => granular_token.to_gid.to_s,
              'scopes' => [a_hash_including('access' => access.upcase)]
            )
          )
        end
      end
    end

    describe 'filters' do
      before do
        send_query
      end

      context 'with { search: "<query>" }' do
        let(:args) { { search: 'special' } }

        it 'returns only personal access tokens that match the query' do
          expect(personal_access_tokens_data).to all(include('name' => 'Special token'))
        end
      end

      context 'with { state: ACTIVE }' do
        let(:args) { { state: :ACTIVE } }

        it 'returns only active personal access tokens' do
          expect(personal_access_tokens_data).to all(include('active' => true))
        end
      end

      context 'with { state: INACTIVE }' do
        let(:args) { { state: :INACTIVE } }

        it 'returns only inactive personal access tokens' do
          expect(personal_access_tokens_data).to all(include('active' => false))
        end
      end

      context 'with { revoked: true }' do
        let(:args) { { revoked: true } }

        it 'returns only revoked personal access tokens' do
          expect(personal_access_tokens_data).to all(include('revoked' => true))
        end
      end

      context 'with { revoked: false }' do
        let(:args) { { revoked: false } }

        it 'returns only non-revoked personal access tokens' do
          expect(personal_access_tokens_data).to all(include('revoked' => false))
        end
      end

      context 'with { expires_after: <date> }' do
        let(:args) { { expires_after: 50.days.from_now.to_date } }

        it 'returns only personal access tokens that expire after the given date' do
          expires_at_dates = personal_access_tokens_data.pluck('expiresAt').map(&:to_date)
          expect(expires_at_dates).to all(be >= args[:expires_after])
        end
      end

      context 'with { created_after: <date> }' do
        let(:args) { { created_after: 1.day.ago } }

        it 'returns only personal access tokens that were created after the given date' do
          created_at_times = personal_access_tokens_data.pluck('createdAt').map(&:in_time_zone)
          expect(created_at_times).to all(be >= args[:created_after])
        end
      end

      context 'with { last_used_after: <date> }' do
        let(:args) { { last_used_after: 2.days.ago } }

        it 'returns only personal access tokens that were last used after the given date' do
          last_used_at_times = personal_access_tokens_data.pluck('lastUsedAt').map(&:in_time_zone)
          expect(last_used_at_times).to all(be >= args[:last_used_after])
        end
      end
    end
  end

  context 'when current user is another user' do
    let_it_be(:current_user) { create(:user) }

    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(*%i[user personalAccessTokens])).to be_blank
    end
  end

  context 'when current user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    it 'returns the personal access tokens of the user' do
      post_graphql(query, current_user: current_user)

      expect(personal_access_tokens_data).to include(
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
