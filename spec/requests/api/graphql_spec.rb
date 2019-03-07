# frozen_string_literal: true
require 'spec_helper'

describe 'GraphQL' do
  include GraphqlHelpers

  let(:query) { graphql_query_for('echo', 'text' => 'Hello world' ) }

  context 'graphql is disabled by feature flag' do
    before do
      stub_feature_flags(graphql: false)
    end

    it 'does not generate a route for GraphQL' do
      expect { post_graphql(query) }.to raise_error(ActionController::RoutingError)
    end
  end

  context 'invalid variables' do
    it 'returns an error' do
      post_graphql(query, variables: "This is not JSON")

      expect(response).to have_gitlab_http_status(422)
      expect(json_response['errors'].first['message']).not_to be_nil
    end
  end

  context 'authentication', :allow_forgery_protection do
    let(:user) { create(:user) }

    it 'allows access to public data without authentication' do
      post_graphql(query)

      expect(graphql_data['echo']).to eq('nil says: Hello world')
    end

    it 'does not authenticate a user with an invalid CSRF' do
      login_as(user)

      post_graphql(query, headers: { 'X-CSRF-Token' => 'invalid' })

      expect(graphql_data['echo']).to eq('nil says: Hello world')
    end

    it 'authenticates a user with a valid session token' do
      # Create a session to get a CSRF token from
      login_as(user)
      get('/')

      post '/api/graphql', params: { query: query }, headers: { 'X-CSRF-Token' => response.session['_csrf_token'] }

      expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
    end

    context 'token authentication' do
      let(:token) { create(:personal_access_token) }

      before do
        stub_authentication_activity_metrics(debug: false)
      end

      it 'Authenticates users with a PAT' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
          .and increment(:user_session_override_counter)
          .and increment(:user_sessionless_authentication_counter)

        post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

        expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
      end

      context 'when the personal access token has no api scope' do
        it 'does not log the user in' do
          token.update(scopes: [:read_user])

          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

          expect(response).to have_gitlab_http_status(200)

          expect(graphql_data['echo']).to eq('nil says: Hello world')
        end
      end
    end
  end
end
