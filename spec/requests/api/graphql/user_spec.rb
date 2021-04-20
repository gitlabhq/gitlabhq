# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  shared_examples 'a working user query' do
    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'includes the user' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['user']).not_to be_nil
    end

    it 'returns no user when global restricted_visibility_levels includes PUBLIC' do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

      post_graphql(query)

      expect(graphql_data['user']).to be_nil
    end
  end

  context 'when id parameter is used' do
    let(:query) { graphql_query_for(:user, { id: current_user.to_global_id.to_s }) }

    it_behaves_like 'a working user query'
  end

  context 'when username parameter is used' do
    let(:query) { graphql_query_for(:user, { username: current_user.username.to_s }) }

    it_behaves_like 'a working user query'
  end

  context 'when username and id parameter are used' do
    let_it_be(:query) do
      graphql_query_for(
        :user,
        { id: current_user.to_global_id.to_s, username: current_user.username },
        'id'
      )
    end

    it 'displays an error' do
      post_graphql(query)

      expect(graphql_errors).to include(
        a_hash_including('message' => a_string_matching(%r{Provide either a single username or id}))
      )
    end
  end
end
