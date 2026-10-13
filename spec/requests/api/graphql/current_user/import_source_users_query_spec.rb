# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying import source users for the current user', feature_category: :importers do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:completed_source_user) do
    create(:import_source_user, :completed, :with_reassigned_by_user, reassign_to_user: user)
  end

  let_it_be(:awaiting_approval_source_user) do
    create(:import_source_user, :awaiting_approval, reassign_to_user: user)
  end

  let_it_be(:other_user_source_user) { create(:import_source_user, :completed) }

  let(:current_user) { user }

  let(:query) do
    graphql_query_for(
      'currentUser',
      {},
      <<~IMPORT_SOURCE_USERS
        importSourceUsers {
          nodes {
            id
            placeholderUser {
              id
            }
            reassignToUser {
              id
            }
            reassignedByUser {
              id
            }
          }
        }
      IMPORT_SOURCE_USERS
    )
  end

  subject(:response_ids) { graphql_data_at('currentUser', 'importSourceUsers', 'nodes', 'id') }

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_user, :read_import_source_user] do
    let(:boundary_object) { :user }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  context 'when user is signed in' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns only completed source users reassigned to the current user' do
      expect(response_ids).to contain_exactly(global_id_of(completed_source_user).to_s)
    end

    context 'when revoke_import_source_user_reassignment feature flag is disabled' do
      before do
        stub_feature_flags(revoke_import_source_user_reassignment: false)
        post_graphql(query, current_user: current_user)
      end

      it 'returns an empty result' do
        expect(response_ids).to be_empty
      end
    end
  end

  it 'avoids N+1 queries', :request_store do
    n_plus_one_query = graphql_query_for(
      'currentUser',
      {},
      <<~IMPORT_SOURCE_USERS
        importSourceUsers {
          nodes {
            id
            placeholderUser {
              id
            }
            reassignToUser {
              id
            }
            reassignedByUser {
              id
            }
          }
        }
      IMPORT_SOURCE_USERS
    )

    post_graphql(n_plus_one_query, current_user: current_user)

    control = ActiveRecord::QueryRecorder.new { post_graphql(n_plus_one_query, current_user: current_user) }

    create(:import_source_user, :completed, :with_reassigned_by_user, reassign_to_user: user)

    expect { post_graphql(n_plus_one_query, current_user: current_user) }.not_to exceed_query_limit(control)
  end

  context 'when user is not signed in' do
    let(:current_user) { nil }

    it 'returns no data' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['currentUser']).to be_nil
    end
  end
end
