# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Glql, feature_category: :custom_dashboards_foundation do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'test-group', developers: user) }
  let_it_be(:project) { create(:project, name: 'test-project', path: 'test-project', namespace: group) }
  let_it_be(:other_project) { create(:project, name: 'other-project', path: 'other-project', namespace: group) }

  let_it_be(:private_project) do
    create(:project, :private, name: 'private-project', path: 'private-project', namespace: group)
  end

  let_it_be(:opened_issue) do
    issue = create(:issue, :opened, project: project, title: 'Opened Issue', description: 'This is opened',
      created_at: 2.days.ago)
    create(:issue_assignee, assignee: user, issue: issue)

    issue
  end

  let_it_be(:closed_issue) do
    create(:issue, :closed, project: project, title: 'Closed Issue', description: 'This is closed',
      created_at: 1.day.ago)
  end

  let_it_be(:other_opened_issue) do
    create(:issue, :opened, project: other_project, title: 'Other Opened Issue',
      created_at: 3.days.ago)
  end

  let(:endpoint) { '/glql' }

  subject(:glql_request) { post api(endpoint, user), params: params }

  before do
    stub_licensed_features(ai_workflows: true)
  end

  describe 'POST /glql' do
    context 'for parameter validation' do
      let(:params) { {} }

      it 'returns 400 when glql_yaml parameter is missing' do
        glql_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('glql_yaml is missing')
      end

      context 'when glql_yaml parameter exceeds limit' do
        let(:params) { { glql_yaml: 'a' * 10_001 } }

        it 'returns 400' do
          glql_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include('Input exceeds maximum size')
        end
      end
    end

    context 'with valid requests' do
      let(:params) { { glql_yaml: "query: group = \"test-group\" AND state = opened" } }

      it 'returns successful response with opened issues', :aggregate_failures do
        glql_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['success']).to be(true)
        expect(json_response['data']['nodes']).to be_an(Array)

        issue_titles = get_issue_titles(json_response)
        expect(issue_titles).to include('Opened Issue', 'Other Opened Issue')
        expect(issue_titles).not_to include('Closed Issue')
      end

      it 'processes frontmatter configuration and returns specified fields' do
        yaml = "---\nfields: id,title,author\ngroup: test-group\n---\nstate = opened"
        post api(endpoint, user), params: { glql_yaml: yaml }

        expect(response).to have_gitlab_http_status(:ok)
        first_issue = get_first_issue(json_response)
        expect(first_issue.keys).to include('id', 'title', 'author')
      end

      it 'applies limit configuration' do
        yaml = "limit: 1\nquery: group = \"test-group\" AND state = opened"
        post api(endpoint, user), params: { glql_yaml: yaml }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['data']['nodes'].size).to eq 1
      end

      where(:description, :glql_yaml, :expected_titles, :excluded_titles) do
        [
          ['project scope in query', 'query: project = "test-group/test-project" AND state = opened',
            ['Opened Issue'], ['Other Opened Issue']],
          ['project scope in config', "---\nproject: test-group/test-project\nfields: title\n---\nstate = opened",
            ['Opened Issue'], ['Other Opened Issue']],
          ['group scope', 'query: group = "test-group" AND state = opened',
            ['Opened Issue', 'Other Opened Issue'], []]
        ]
      end

      with_them do
        it 'applies scope correctly' do
          post api(endpoint, user), params: { glql_yaml: glql_yaml }

          expect(response).to have_gitlab_http_status(:ok)
          expect(get_issue_titles(json_response)).to include(*expected_titles)
          expect(get_issue_titles(json_response)).not_to include(*excluded_titles) if excluded_titles.any?
        end
      end

      context 'with sort configuration' do
        where(:params, :ordered_titles) do
          [
            [{
              glql_yaml: <<~YAML
                 fields: title
                 sort: created asc
                 query: group = "test-group" AND state = opened
              YAML
            }, ['Other Opened Issue', 'Opened Issue']],
            [{
              glql_yaml: <<~YAML
                 fields: title
                 sort: created desc
                 query: group = "test-group" AND state = opened
              YAML
            }, ['Opened Issue', 'Other Opened Issue']]
          ]
        end

        with_them do
          it 'applies sort order correctly', :aggregate_failures do
            glql_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['success']).to be(true)

            expect(get_issue_titles(json_response)).to eq(ordered_titles)
          end
        end
      end

      it 'filters by state correctly' do
        post api(endpoint, user), params: { glql_yaml: "query: group = \"test-group\" AND state = closed" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(get_issue_titles(json_response)).to include('Closed Issue')
        expect(get_issue_titles(json_response)).not_to include('Opened Issue', 'Other Opened Issue')
      end
    end

    context 'with error conditions' do
      where(:description, :glql_yaml, :error_message) do
        [
          ['invalid GLQL syntax', 'invalid syntax @@@ ###', 'Error: Unexpected `syntax @@@ ###`'],
          ['non-existent project', 'query: project = "test-group/non-existent" AND state = opened',
            'Error: Project does not exist or you do not have access to it'],
          ['non-existent group', 'query: group = "non-existent" AND state = opened',
            'Error: Group does not exist or you do not have access to it']
        ]
      end

      with_them do
        it 'returns bad request with appropriate error' do
          post api(endpoint, user), params: { glql_yaml: glql_yaml }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include(error_message)
        end
      end
    end

    context 'with authentication and authorization' do
      let(:base_params) { { glql_yaml: "query: group = \"test-group\" AND state = opened" } }

      where(:description, :auth_setup, :expected_status) do
        [
          ['AI workflows OAuth token', -> { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }, :ok],
          ['read API OAuth token', -> { create(:oauth_access_token, user: user, scopes: [:read_api]) }, :ok],
          ['limited OAuth token', -> { create(:oauth_access_token, user: user, scopes: [:read_user]) }, :forbidden],
          ['no authentication', -> { nil }, :ok]
        ]
      end

      with_them do
        it 'enforces access control correctly' do
          token = instance_exec(&auth_setup)
          post api(endpoint, oauth_access_token: token), params: base_params

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end

      it 'denies access to private projects without authentication' do
        params = { glql_yaml: "query: project = \"test-group/private-project\" AND state = opened" }
        post api(endpoint), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('Error: Project does not exist or you do not have access to it')
      end
    end

    it 'returns 429 when rate limited' do
      yaml = "query: group = \"test-group\" AND state = opened"
      query_sha = Digest::SHA256.hexdigest(yaml)
      allow(Gitlab::ApplicationRateLimiter).to receive(:peek).with(:glql, scope: query_sha).and_return(true)

      post api(endpoint, user), params: { glql_yaml: yaml }

      expect(response).to have_gitlab_http_status(:too_many_requests)
      expect(json_response['error']).to include('Query temporarily blocked')
    end

    context 'with query execution errors' do
      it 'returns 400 when GraphQL query execution fails' do
        yaml = <<~YAML
          fields: nonExistentField
          query: group = "test-group" AND state = opened
        YAML

        post api(endpoint, user), params: { glql_yaml: yaml }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include("Field 'nonExistentField' doesn't exist")
      end
    end

    context 'with limit parameter processing' do
      before do
        create_list(:issue, 5, :opened, project: project)
      end

      where(:limit_value, :expected_max_size) do
        [
          [nil, 100], # default limit
          [3, 3], # valid limit
          [150, 100], # exceeds maximum
          [0, 100] # invalid, uses default
        ]
      end

      with_them do
        it 'applies limit correctly' do
          yaml = if limit_value
                   "limit: #{limit_value}\nquery: group = \"test-group\" AND state = opened"
                 else
                   "query: group = \"test-group\" AND state = opened"
                 end

          post api(endpoint, user), params: { glql_yaml: yaml }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['data']['nodes'].size).to be <= expected_max_size
        end
      end
    end

    it 'logs execution' do
      expect(Gitlab::GraphqlLogger).to receive(:info).at_least(:once).and_call_original

      post api(endpoint, user), params: { glql_yaml: "query: group = \"test-group\" AND state = opened" }

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with variables from GLQL compilation' do
      before do
        create_list(:issue, 5, :opened, project: project)
      end

      it 'processes variables and returns requested fields' do
        yaml = "fields: state,assignees\nquery: group = \"test-group\" AND state = opened AND assignee = currentUser()"
        post api(endpoint, user), params: { glql_yaml: yaml }

        expect(response).to have_gitlab_http_status(:ok)
        first_issue = get_first_issue(json_response)
        expect(first_issue.keys).to include('state', 'assignees')
        expect(first_issue['state']).to eq('OPEN')
        expect(first_issue['assignees']['nodes'].first['username']).to eq(user.username)
      end

      it 'supports pagination with variables' do
        post api(endpoint, user), params: { glql_yaml: "limit: 2\nquery: group = \"test-group\" AND state = opened" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['data']['pageInfo']).to include('hasNextPage' => true, 'endCursor' => be_present)
        expect(json_response['data']['nodes'].size).to eq(2)
      end
    end

    context 'with pagination' do
      before do
        create_list(:issue, 10, :opened, project: project)
      end

      it 'returns first page with pageInfo' do
        post api(endpoint, user), params: { glql_yaml: "limit: 3\nquery: group = \"test-group\" AND state = opened" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['data']['nodes'].size).to eq(3)
        expect(json_response['data']['pageInfo']).to include(
          'hasNextPage' => true,
          'endCursor' => be_present
        )
      end

      it 'returns subsequent page using after cursor' do
        # Get first page
        post api(endpoint, user), params: { glql_yaml: "limit: 3\nquery: group = \"test-group\" AND state = opened" }
        first_page_cursor = json_response['data']['pageInfo']['endCursor']
        first_page_titles = get_issue_titles(json_response)

        # Get second page
        post api(endpoint, user), params: {
          glql_yaml: "limit: 3\nquery: group = \"test-group\" AND state = opened",
          after: first_page_cursor
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['data']['nodes'].size).to eq(3)
        expect(json_response['data']['pageInfo']).to include(
          'hasNextPage' => true,
          'endCursor' => be_present
        )
        second_page_titles = get_issue_titles(json_response)
        expect(second_page_titles).not_to eq(first_page_titles)
      end

      it 'returns hasNextPage as false on last page' do
        post api(endpoint, user), params: { glql_yaml: "limit: 20\nquery: group = \"test-group\" AND state = opened" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['data']['pageInfo']).to include('hasNextPage' => false)
      end

      it 'handles empty variables hash' do
        allow(::Glql).to receive(:compile).and_wrap_original do |method, *args|
          result = method.call(*args)
          result['variables'] = {}
          result
        end

        post api(endpoint, user), params: { glql_yaml: "query: group = \"test-group\" AND state = opened" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['success']).to be(true)
      end
    end

    context 'with aliased display fields' do
      it 'uses the alias as the key in the fields metadata', :aggregate_failures do
        yaml = "fields: description, openedAt\nquery: group = \"test-group\" AND state = opened"
        post api(endpoint, user), params: { glql_yaml: yaml }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['fields'].pluck('key')).to eq(%w[description openedAt])
      end

      it 'returns non-nil values under the aliased keys in node data', :aggregate_failures do
        yaml = "fields: description, openedAt\nquery: group = \"test-group\" AND state = opened"
        post api(endpoint, user), params: { glql_yaml: yaml }

        expect(response).to have_gitlab_http_status(:ok)
        node = json_response['data']['nodes'].find { |n| n['title'] == 'Opened Issue' }
        expect(node['description']).to include('This is opened')
        expect(node['openedAt']).to be_present
      end
    end

    context 'with analytics mode for code suggestions' do
      let(:params) do
        { glql_yaml: <<~YAML }
          query: type = CodeSuggestion and language = "ruby"
          mode: "analytics"
          dimensions: "language"
          metrics: "totalCount, acceptanceRate"
          project: "#{project.full_path}"
        YAML
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(glql_code_suggestion_analytics_aggregation: false)
        end

        it 'returns an error' do
          glql_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error'])
            .to include('code suggestions` requires the `glqlCodeSuggestions` feature flag to be enabled')
        end
      end

      context 'when the feature flag is enabled' do
        before do
          stub_feature_flags(glql_code_suggestion_analytics_aggregation: project)
        end

        it 'returns an error because the analytics schema is not available in FOSS' do
          glql_request

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  private

  def get_first_issue(response)
    response['data']['nodes'].first
  end

  def get_issue_titles(response)
    response['data']['nodes'].pluck('title')
  end
end
