# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'GraphQL', feature_category: :shared do
  include GraphqlHelpers
  include AfterNextHelpers

  let(:query) { graphql_query_for('echo', text: 'Hello world') }
  let(:mutation) { 'mutation { echoCreate(input: { messages: ["hello", "world"] }) { echoes } }' }

  let_it_be(:user) { create(:user) }

  describe 'logging' do
    shared_examples 'logging a graphql query' do
      let(:expected_execute_query_log) do
        {
          "correlation_id" => kind_of(String),
          "meta.caller_id" => "graphql:unknown",
          "meta.client_id" => kind_of(String),
          "meta.feature_category" => "not_owned",
          "meta.remote_ip" => kind_of(String),
          "query_analysis.duration_s" => kind_of(Numeric),
          "query_analysis.depth" => 1,
          "query_analysis.complexity" => 1,
          "query_analysis.used_fields" => ['Query.echo'],
          "query_analysis.used_deprecated_fields" => [],
          "query_analysis.used_deprecated_arguments" => [],
          # query_fingerprint starts with operation name
          query_fingerprint: %r{^anonymous/},
          duration_s: kind_of(Numeric),
          trace_type: 'execute_query',
          operation_name: nil,
          # operation_fingerprint starts with operation name
          operation_fingerprint: %r{^anonymous/},
          is_mutation: false,
          variables: variables.to_s,
          query_string: query
        }
      end

      it 'logs a query with the expected params' do
        expect(Gitlab::GraphqlLogger).to receive(:info).with(expected_execute_query_log).once

        post_graphql(query, variables: variables)
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
        allow(GraphQL::Analysis::AST).to receive(:analyze_query)
          .and_call_original
        allow(GraphQL::Analysis::AST).to receive(:analyze_query)
          .with(anything, Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer::ALL_ANALYZERS, anything)
          .and_raise(StandardError.new("oh noes!"))
      end

      it 'logs the exception in Sentry and continues with the request' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception).at_least(:once)
        expect(Gitlab::GraphqlLogger)
          .to receive(:info)

        post_graphql(query, variables: {})
      end
    end
  end

  context 'when executing mutations' do
    let(:mutation_with_variables) do
      <<~GQL
      mutation($a: String!, $b: String!) {
        echoCreate(input: { messages: [$a, $b] }) { echoes }
      }
      GQL
    end

    context 'with POST' do
      it 'succeeds' do
        post_graphql(mutation, current_user: user)

        expect(graphql_data_at(:echo_create, :echoes)).to eq %w[hello world]
      end

      context 'with variables' do
        it 'succeeds' do
          post_graphql(mutation_with_variables, current_user: user, variables: { a: 'Yo', b: 'there' })

          expect(graphql_data_at(:echo_create, :echoes)).to eq %w[Yo there]
        end
      end
    end

    context 'with GET' do
      it 'fails' do
        get_graphql(mutation, current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => /Mutations are forbidden/))
      end

      context 'with variables' do
        it 'fails' do
          get_graphql(mutation_with_variables, current_user: user, variables: { a: 'Yo', b: 'there' })

          expect(graphql_errors).to include(a_hash_including('message' => /Mutations are forbidden/))
        end
      end
    end
  end

  context 'when executing queries' do
    context 'with POST' do
      it 'succeeds' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:echo)).to include 'Hello world'
      end
    end

    context 'with GET' do
      it 'succeeds' do
        get_graphql(query, current_user: user)

        expect(graphql_data_at(:echo)).to include 'Hello world'
      end
    end
  end

  context 'when selecting a query by operation name' do
    let(:query) { "query A #{graphql_query_for('echo', text: 'Hello world')}" }
    let(:mutation) { 'mutation B { echoCreate(input: { messages: ["hello", "world"] }) { echoes } }' }

    let(:combined) { [query, mutation].join("\n\n") }

    context 'with POST' do
      it 'succeeds when selecting the query' do
        post_graphql(combined, current_user: user, params: { operationName: 'A' })

        resp = json_response

        expect(resp.dig('data', 'echo')).to include 'Hello world'
      end

      it 'succeeds when selecting the mutation' do
        post_graphql(combined, current_user: user, params: { operationName: 'B' })

        resp = json_response

        expect(resp.dig('data', 'echoCreate', 'echoes')).to eq %w[hello world]
      end
    end

    context 'with GET' do
      it 'succeeds when selecting the query' do
        get_graphql(combined, current_user: user, params: { operationName: 'A' })

        resp = json_response

        expect(resp.dig('data', 'echo')).to include 'Hello world'
      end

      it 'fails when selecting the mutation' do
        get_graphql(combined, current_user: user, params: { operationName: 'B' })

        resp = json_response

        expect(resp.dig('errors', 0, 'message')).to include "Mutations are forbidden"
      end
    end
  end

  context 'when batching mutations and queries' do
    let(:batched) do
      [
        { query: "query A #{graphql_query_for('echo', text: 'Hello world')}" },
        { query: 'mutation B { echoCreate(input: { messages: ["hello", "world"] }) { echoes } }' }
      ]
    end

    context 'with POST' do
      it 'succeeds' do
        post_multiplex(batched, current_user: user)

        resp = json_response

        expect(resp.dig(0, 'data', 'echo')).to include 'Hello world'
        expect(resp.dig(1, 'data', 'echoCreate', 'echoes')).to eq %w[hello world]
      end
    end

    context 'with GET' do
      it 'fails with a helpful error message' do
        get_multiplex(batched, current_user: user)

        resp = json_response

        expect(resp.dig('errors', 0, 'message')).to include "Mutations are forbidden"
      end
    end
  end

  context 'with invalid variables' do
    it 'returns an error' do
      post_graphql(query, variables: "This is not JSON")

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['errors'].first['message']).not_to be_nil
    end
  end

  describe 'authentication', :allow_forgery_protection do
    it 'allows access to public data without authentication' do
      post_graphql(query)

      expect(graphql_data['echo']).to eq('nil says: Hello world')
    end

    describe 'request forgery protection' do
      it 'allows queries even with an invalid CSRF token' do
        login_as(user)

        stub_authentication_activity_metrics do |metrics|
          expect(metrics)
            .to increment(:user_authenticated_counter)
        end

        post_graphql(query, headers: { 'X-CSRF-Token' => 'invalid' })

        expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
      end

      it 'does not allow mutations with an invalid CSRF token' do
        login_as(user)

        stub_authentication_activity_metrics do |metrics|
          expect(metrics)
            .to increment(:user_authenticated_counter)

          expect(metrics.user_csrf_token_invalid_counter)
            .to receive(:increment).with(controller: 'GraphqlController', auth: 'session')
        end

        post_graphql(mutation, headers: { 'X-CSRF-Token' => 'invalid' })

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end

      it 'allows mutations with a valid CSRF token' do
        # Create a session to get a CSRF token from
        login_as(user)
        get('/')

        stub_authentication_activity_metrics do |metrics|
          expect(metrics.user_csrf_token_invalid_counter).not_to receive(:increment)
        end

        post_graphql(mutation, headers: { 'X-CSRF-Token' => session['_csrf_token'] })

        expect(graphql_data_at(:echo_create, :echoes)).to eq %w[hello world]
      end

      context 'when batching mutations and queries' do
        let(:batched) do
          [
            { query: "query A #{graphql_query_for('echo', text: 'Hello world')}" },
            { query: 'mutation B { echoCreate(input: { messages: ["hello", "world"] }) { echoes } }' }
          ]
        end

        it 'does not allow multiplexed request with an invalid CSRF token' do
          login_as(user)

          post_multiplex(batched, headers: { 'X-CSRF-Token' => 'invalid' })

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end

        it 'allows multiplexed request with valid CSRF token' do
          login_as(user)
          get('/')

          post_multiplex(batched, headers: { 'X-CSRF-Token' => session['_csrf_token'] })

          expect(json_response[0].dig('data', 'echo')).to eq("\"#{user.username}\" says: Hello world")
          expect(json_response[1].dig('data', 'echoCreate', 'echoes')).to eq %w[hello world]
        end
      end
    end

    context 'with token authentication' do
      let(:token) { create(:personal_access_token, user: user) }

      it 'authenticates users with a PAT' do
        stub_authentication_activity_metrics(debug: false) do |metrics|
          expect(metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_session_override_counter)
            .and increment(:user_sessionless_authentication_counter)

          expect(metrics.user_csrf_token_invalid_counter).not_to receive(:increment)
        end

        post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

        expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
      end

      context 'when two-factor authentication is required' do
        before do
          stub_application_setting(require_two_factor_authentication: true)
        end

        it 'does not enforce 2FA' do
          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

          expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
        end
      end

      context 'when user also has a valid session' do
        let_it_be(:other_user) { create(:user) }

        before do
          login_as(other_user)
          get('/')
        end

        it 'authenticates as PAT user' do
          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token, 'X-CSRF-Token' => session['_csrf_token'] })

          expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
        end

        it 'authenticates as PAT user even when CSRF token is invalid' do
          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token, 'X-CSRF-Token' => 'invalid' })

          expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
        end
      end

      shared_examples 'valid token' do
        it 'accepts from header' do
          post_graphql(query, headers: { 'Authorization' => "Bearer #{token}" })

          expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
        end

        it 'accepts from access_token parameter' do
          post "/api/graphql?access_token=#{token}", params: { query: query }

          expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
        end

        it 'accepts from private_token parameter' do
          post "/api/graphql?private_token=#{token}", params: { query: query }

          expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
        end
      end

      context 'with oAuth user access token' do
        let(:oauth_application) do
          create(
            :oauth_application,
            scopes: 'api read_user',
            redirect_uri: 'http://example.com',
            confidential: true
          )
        end

        let(:oauth_access_token) do
          create(
            :oauth_access_token,
            application: oauth_application,
            resource_owner: user,
            scopes: 'api'
          )
        end

        let(:token) { oauth_access_token.plaintext_token }

        # Doorkeeper does not support the private_token=? param
        # https://github.com/doorkeeper-gem/doorkeeper/blob/960f1501131683b16c2704d1b6f9597b9583b49d/lib/doorkeeper/oauth/token.rb#L26
        # so we cannot use shared examples here
        it 'accepts from header' do
          post_graphql(query, headers: { 'Authorization' => "Bearer #{token}" })

          expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
        end

        it 'accepts from access_token parameter' do
          post "/api/graphql?access_token=#{token}", params: { query: query }

          expect(graphql_data['echo']).to eq("\"#{user.username}\" says: Hello world")
        end
      end

      context 'with personal access token' do
        let(:personal_access_token) { create(:personal_access_token, user: user) }
        let(:token) { personal_access_token.token }

        it_behaves_like 'valid token'
      end

      context 'with group or project access token' do
        let_it_be(:user) { create(:user, :project_bot) }
        let_it_be(:project_access_token) { create(:personal_access_token, user: user) }

        let(:token) { project_access_token.token }

        it_behaves_like 'valid token'
      end

      describe 'invalid authentication types' do
        let(:query) { 'query { currentUser { id, username } }' }

        describe 'with git-lfs token' do
          let(:lfs_token) { Gitlab::LfsToken.new(user, nil).token }
          let(:header_token) { Base64.encode64("#{user.username}:#{lfs_token}") }
          let(:headers) do
            { 'Authorization' => "Basic #{header_token}" }
          end

          it 'does not authenticate users with an LFS token' do
            post '/api/graphql.git', params: { query: query }, headers: headers

            expect(graphql_data['currentUser']).to be_nil
          end
        end

        describe 'with job token' do
          let(:project) do
            create(:project).tap do |proj|
              proj.add_owner(user)
            end
          end

          let(:job) { create(:ci_build, :running, project: project, user: user) }
          let(:job_token) { job.token }

          it 'raises "Invalid token" error' do
            post '/api/graphql', params: { query: query, job_token: job_token }

            expect_graphql_errors_to_include(/Invalid token/)
          end
        end

        describe 'with static object token' do
          let(:headers) do
            { 'X-Gitlab-Static-Object-Token' => user.static_object_token }
          end

          it 'does not authenticate user from header' do
            post '/api/graphql', params: { query: query }, headers: headers

            expect(graphql_data['currentUser']).to be_nil
          end

          it 'does not authenticate user from parameter' do
            post "/api/graphql?token=#{user.static_object_token}", params: { query: query }

            expect_graphql_errors_to_include(/Invalid token/)
          end
        end

        describe 'with dependency proxy token' do
          include DependencyProxyHelpers
          let(:token) { build_jwt(user).encoded }
          let(:headers) do
            { 'Authorization' => "Bearer #{token}" }
          end

          it 'does not authenticate user from dependency proxy token in headers' do
            post '/api/graphql', params: { query: query }, headers: headers

            expect_graphql_errors_to_include(/Invalid token/)
          end

          it 'does not authenticate user from dependency proxy token in parameter' do
            post "/api/graphql?access_token=#{token}", params: { query: query }

            expect_graphql_errors_to_include(/Invalid token/)
          end
        end
      end

      it 'prevents access by deactived users' do
        token.user.deactivate!

        post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

        expect(graphql_errors).to include({ 'message' => /API not accessible/ })
      end

      context 'when user with expired password' do
        let_it_be(:user) { create(:user, password_expires_at: 2.minutes.ago) }

        it 'does not authenticate user' do
          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

          expect(response).to have_gitlab_http_status(:unauthorized)

          expect_graphql_errors_to_include('Invalid token')
        end
      end

      context 'when password expiration is not applicable' do
        context 'when ldap user' do
          let_it_be(:user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

          it 'authenticates user' do
            post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

            expect(response).to have_gitlab_http_status(:ok)

            expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
          end
        end
      end

      context 'when the personal access token has no api scope' do
        it 'does not log the user in' do
          token.update!(scopes: [:read_user])

          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

          expect(response).to have_gitlab_http_status(:unauthorized)

          expect_graphql_errors_to_include('Invalid token')
        end
      end

      context 'when the personal access token has read_api scope' do
        it 'they can perform a query' do
          token.update!(scopes: [:read_api])

          post_graphql(query, headers: { 'PRIVATE-TOKEN' => token.token })

          expect(response).to have_gitlab_http_status(:ok)

          expect(graphql_data['echo']).to eq("\"#{token.user.username}\" says: Hello world")
        end

        it 'they cannot perform a mutation' do
          token.update!(scopes: [:read_api])

          post_graphql(mutation, headers: { 'PRIVATE-TOKEN' => token.token })

          # The response status is OK but they get no data back and they get errors.
          expect(response).to have_gitlab_http_status(:ok)
          expect(graphql_data['echoCreate']).to be_nil

          expect_graphql_errors_to_include("does not exist or you don't have permission")
        end
      end

      context 'when request is cross-origin' do
        it 'does not allow cookie credentials' do
          post '/api/graphql', headers: { 'Origin' => 'http://notgitlab.com', 'Access-Control-Request-Method' => 'POST' }

          expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
          expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
        end
      end
    end
  end

  describe 'testing for Gitaly calls' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }

    let(:query) do
      graphql_query_for(
        :project,
        { full_path: project.full_path },
        'id'
      )
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
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).once

        post_graphql(query, current_user: user)
      end
    end
  end

  describe 'resolver complexity' do
    let_it_be(:project) { create(:project, :public) }

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field(resource, {}, 'edges { node { iid } }')
      )
    end

    before do
      stub_const('GitlabSchema::DEFAULT_MAX_COMPLEXITY', 6)
    end

    context 'when fetching single resource' do
      let(:resource) { 'issues(first: 1)' }

      it 'processes the query' do
        post_graphql(query)

        expect(graphql_errors).to be_nil
      end
    end

    context 'when fetching too many resources' do
      let(:resource) { 'issues(first: 100)' }

      it 'returns an error' do
        post_graphql(query)

        expect_graphql_errors_to_include(/which exceeds max complexity/)
      end
    end
  end

  describe 'complexity limits' do
    let_it_be(:project) { create(:project, :public) }

    let!(:user) { create(:user) }

    let(:query_fields) do
      <<~QUERY
      id
      QUERY
    end

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_fields
      )
    end

    before do
      stub_const('GitlabSchema::DEFAULT_MAX_COMPLEXITY', 1)
    end

    context 'unauthenticated user' do
      subject { post_graphql(query) }

      it 'raises a complexity error' do
        subject

        expect_graphql_errors_to_include(/which exceeds max complexity/)
      end
    end

    context 'authenticated user' do
      subject { post_graphql(query, current_user: user) }

      it 'does not raise an error as it uses the `AUTHENTICATED_MAX_COMPLEXITY`' do
        subject

        expect(graphql_errors).to be_nil
      end
    end
  end

  describe 'keyset pagination' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issues) { create_list(:issue, 10, project: project, created_at: Time.now.change(usec: 200)) }

    let(:page_size) { 6 }
    let(:issues_edges) { %w[project issues edges] }
    let(:end_cursor) { %w[project issues pageInfo endCursor] }
    let(:query) do
      <<~GRAPHQL
        query project($fullPath: ID!, $first: Int, $after: String) {
            project(fullPath: $fullPath) {
              issues(first: $first, after: $after) {
                edges { node { iid } }
                pageInfo { endCursor }
              }
            }
        }
      GRAPHQL
    end

    def execute_query(after: nil)
      post_graphql(
        query,
        current_user: nil,
        variables: {
          fullPath: project.full_path,
          first: page_size,
          after: after
        }
      )
    end

    it 'paginates datetimes correctly when they have millisecond data' do
      execute_query
      first_page = graphql_data
      edges = first_page.dig(*issues_edges)
      cursor = first_page.dig(*end_cursor)

      expect(edges.count).to eq(6)
      expect(edges.last['node']['iid']).to eq(issues[4].iid.to_s)

      execute_query(after: cursor)
      second_page = graphql_data
      edges = second_page.dig(*issues_edges)

      expect(edges.count).to eq(4)
      expect(edges.last['node']['iid']).to eq(issues[0].iid.to_s)
    end
  end
end
