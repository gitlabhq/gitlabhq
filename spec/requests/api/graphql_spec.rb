# frozen_string_literal: true
require 'spec_helper'

describe 'GraphQL' do
  include GraphqlHelpers

  let(:query) { graphql_query_for('echo', 'text' => 'Hello world' ) }

  context 'logging' do
    shared_examples 'logging a graphql query' do
      let(:expected_params) do
        { query_string: query, variables: variables.to_s, duration: anything, depth: 1, complexity: 1 }
      end

      it 'logs a query with the expected params' do
        expect(Gitlab::GraphqlLogger).to receive(:info).with(expected_params).once

        post_graphql(query, variables: variables)
      end

      it 'does not instantiate any query analyzers' do # they are static and re-used
        expect(GraphQL::Analysis::QueryComplexity).not_to receive(:new)
        expect(GraphQL::Analysis::QueryDepth).not_to receive(:new)

        2.times { post_graphql(query, variables: variables) }
      end
    end

    context 'with no variables' do
      let(:variables) { {} }

      it_behaves_like 'logging a graphql query'
    end

    context 'with variables' do
      let(:variables) do
        { "foo" => "bar" }
      end

      it_behaves_like 'logging a graphql query'
    end

    context 'when there is an error in the logger' do
      before do
        allow_any_instance_of(Gitlab::Graphql::QueryAnalyzers::LoggerAnalyzer).to receive(:process_variables).and_raise(StandardError.new("oh noes!"))
      end

      it 'logs the exception in Sentry and continues with the request' do
        expect(Gitlab::Sentry).to receive(:track_and_raise_for_dev_exception).at_least(1).times
        expect(Gitlab::GraphqlLogger).to receive(:info)

        post_graphql(query, variables: {})
      end
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

  describe 'testing for Gitaly calls' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }

    let(:query) do
      graphql_query_for('project', { 'fullPath' => project.full_path }, %w(id))
    end

    before do
      project.add_developer(user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: user)
      end
    end

    context 'when Gitaly is called' do
      before do
        allow(Gitlab::GitalyClient).to receive(:get_request_count).and_return(1, 2)
      end

      it "logs a warning that the 'calls_gitaly' field declaration is missing" do
        expect(Gitlab::Sentry).to receive(:track_and_raise_for_dev_exception).once

        post_graphql(query, current_user: user)
      end
    end
  end
end
