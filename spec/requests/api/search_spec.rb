# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Search, :clean_gitlab_redis_rate_limiting, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :wiki_repo, :public, name: 'awesome project', group: group) }
  let_it_be(:repo_project) { create(:project, :public, :repository, group: group) }

  before do
    allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).and_return(0)
  end

  shared_examples 'response is correct' do |schema:, size: 1|
    it { expect(response).to have_gitlab_http_status(:ok) }
    it { expect(response).to match_response_schema(schema) }
    it { expect(response).to include_limited_pagination_headers }
    it { expect(json_response.size).to eq(size) }
  end

  shared_examples 'apdex recorded' do |scope:, level:, search: ''|
    it 'increments the custom search sli apdex' do
      expect(Gitlab::Metrics::GlobalSearchSlis).to receive(:record_apdex).with(
        elapsed: a_kind_of(Numeric),
        search_scope: scope,
        search_type: 'basic',
        search_level: level
      )

      get api(endpoint, user), params: { scope: scope, search: search }
    end
  end

  shared_examples 'orderable by created_at' do |scope:|
    it 'allows ordering results by created_at asc' do
      get api(endpoint, user), params: { scope: scope, search: 'sortable', order_by: 'created_at', sort: 'asc' }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response.count).to be > 1

      created_ats = json_response.map { |r| Time.parse(r['created_at']) }
      expect(created_ats.uniq.count).to be > 1

      expect(created_ats).to eq(created_ats.sort)
    end

    it 'allows ordering results by created_at desc' do
      get api(endpoint, user), params: { scope: scope, search: 'sortable', order_by: 'created_at', sort: 'desc' }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response.count).to be > 1

      created_ats = json_response.map { |r| Time.parse(r['created_at']) }
      expect(created_ats.uniq.count).to be > 1

      expect(created_ats).to eq(created_ats.sort.reverse)
    end
  end

  shared_examples 'issues orderable by created_at' do
    before do
      create_list(:issue, 3, title: 'sortable item', project: project)
    end

    it_behaves_like 'orderable by created_at', scope: :issues
  end

  shared_examples 'merge_requests orderable by created_at' do
    before do
      create_list(:merge_request, 3, :unique_branches, title: 'sortable item', target_project: repo_project, source_project: repo_project)
    end

    it_behaves_like 'orderable by created_at', scope: :merge_requests
  end

  shared_examples 'pagination' do |scope:, search: ''|
    it 'returns a different result for each page' do
      get api(endpoint, user), params: { scope: scope, search: search, page: 1, per_page: 1 }
      first = json_response.first

      get api(endpoint, user), params: { scope: scope, search: search, page: 2, per_page: 1 }
      second = Gitlab::Json.parse(response.body).first

      expect(first).not_to eq(second)
    end

    it 'returns 1 result when per_page is 1' do
      get api(endpoint, user), params: { scope: scope, search: search, per_page: 1 }

      expect(json_response.count).to eq(1)
    end

    it 'returns 2 results when per_page is 2' do
      get api(endpoint, user), params: { scope: scope, search: search, per_page: 2 }

      expect(Gitlab::Json.parse(response.body).count).to eq(2)
    end
  end

  shared_examples 'filter by state' do |scope:, search:|
    it 'respects scope filtering' do
      get api(endpoint, user), params: { scope: scope, search: search, state: state }

      documents = Gitlab::Json.parse(response.body)

      expect(documents.count).to eq(1)
      expect(documents.first['state']).to eq(state)
    end
  end

  shared_examples 'filter by confidentiality' do |scope:, search:|
    it 'respects confidentiality filtering' do
      get api(endpoint, user), params: { scope: scope, search: search, confidential: confidential.to_s }

      documents = Gitlab::Json.parse(response.body)

      expect(documents.count).to eq(1)
      expect(documents.first['confidential']).to eq(confidential)
    end
  end

  describe 'GET /search' do
    let(:endpoint) { '/search' }

    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api(endpoint), params: { scope: 'projects', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when DB timeouts occur from global searches', :aggregate_failures do
      %w[
        issues
        merge_requests
        milestones
        projects
        snippet_titles
        users
      ].each do |scope|
        it "returns a 408 error if search with scope: #{scope} times out" do
          allow(SearchService).to receive(:new).and_raise ActiveRecord::QueryCanceled
          get api(endpoint, user), params: { scope: scope, search: 'awesome' }
          expect(response).to have_gitlab_http_status(:request_timeout)
        end
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api(endpoint, user), params: { scope: 'unsupported', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api(endpoint, user), params: { search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when there is a search error' do
      let(:results) { instance_double('Gitlab::SearchResults', failed?: true, error: 'failed to parse query') }

      before do
        allow_next_instance_of(SearchService) do |service|
          allow(service).to receive(:search_objects).and_return([])
          allow(service).to receive(:search_results).and_return(results)
        end
      end

      it 'returns 400 error' do
        get api(endpoint, user), params: { scope: 'issues', search: 'expected to fail' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with correct params' do
      [:issues, :merge_requests, :projects, :milestones, :users, :snippet_titles].each do |scope|
        context "with correct params for scope #{scope}" do
          it_behaves_like 'internal event tracking' do
            let(:event) { 'perform_search' }
            let(:category) { described_class.to_s }
            let(:project) { nil }
            let(:namespace) { nil }

            subject(:tracked_event) do
              get api(endpoint, user), params: { scope: scope, search: 'foobar' }
            end
          end
        end
      end

      context 'for projects scope' do
        before do
          get api(endpoint, user), params: { scope: 'projects', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'

        it_behaves_like 'pagination', scope: :projects

        it_behaves_like 'apdex recorded', scope: 'projects', level: 'global'
      end

      context 'for issues scope' do
        context 'without filtering by state' do
          before do
            create(:issue, project: project, title: 'awesome issue')

            get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/issues'

          it_behaves_like 'apdex recorded', scope: 'issues', level: 'global'

          it_behaves_like 'issues orderable by created_at'

          describe 'pagination' do
            before do
              create(:issue, project: project, title: 'another issue')
            end

            include_examples 'pagination', scope: :issues
          end
        end

        context 'filter by state' do
          before do
            create(:issue, project: project, title: 'awesome opened issue')
            create(:issue, :closed, project: project, title: 'awesome closed issue')
          end

          context 'state: opened' do
            let(:state) { 'opened' }

            include_examples 'filter by state', scope: :issues, search: 'awesome'
          end

          context 'state: closed' do
            let(:state) { 'closed' }

            include_examples 'filter by state', scope: :issues, search: 'awesome'
          end
        end

        context 'filter by confidentiality' do
          before do
            create(:issue, project: project, author: user, title: 'awesome non-confidential issue')
            create(:issue, :confidential, project: project, author: user, title: 'awesome confidential issue')
          end

          context 'confidential: true' do
            let(:confidential) { true }

            include_examples 'filter by confidentiality', scope: :issues, search: 'awesome'
          end

          context 'confidential: false' do
            let(:confidential) { false }

            include_examples 'filter by confidentiality', scope: :issues, search: 'awesome'
          end
        end
      end

      context 'for merge_requests scope' do
        context 'without filtering by state' do
          before do
            create(:merge_request, source_project: repo_project, title: 'awesome mr')

            get api(endpoint, user), params: { scope: 'merge_requests', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'

          it_behaves_like 'apdex recorded', scope: 'merge_requests', level: 'global'

          it_behaves_like 'merge_requests orderable by created_at'

          describe 'pagination' do
            before do
              create(:merge_request, source_project: repo_project, title: 'another mr', target_branch: 'another_branch')
            end

            include_examples 'pagination', scope: :merge_requests
          end
        end

        context 'filter by state' do
          before do
            create(:merge_request, source_project: project, title: 'awesome opened mr')
            create(:merge_request, :closed, project: project, title: 'awesome closed mr')
          end

          context 'state: opened' do
            let(:state) { 'opened' }

            include_examples 'filter by state', scope: :merge_requests, search: 'awesome'
          end

          context 'state: closed' do
            let(:state) { 'closed' }

            include_examples 'filter by state', scope: :merge_requests, search: 'awesome'
          end
        end
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')
        end

        context 'when user can read project milestones' do
          before do
            get api(endpoint, user), params: { scope: 'milestones', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'

          it_behaves_like 'apdex recorded', scope: 'milestones', level: 'global'

          describe 'pagination' do
            before do
              create(:milestone, project: project, title: 'another milestone')
            end

            include_examples 'pagination', scope: :milestones
          end
        end

        context 'when user cannot read project milestones' do
          before do
            project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
            project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
          end

          it 'returns empty array' do
            get api(endpoint, user), params: { scope: 'milestones', search: 'awesome' }

            milestones = json_response

            expect(milestones).to be_empty
          end
        end
      end

      context 'for users scope' do
        before do
          create(:user, name: 'billy')

          get api(endpoint, user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'

        it_behaves_like 'pagination', scope: :users

        it_behaves_like 'apdex recorded', scope: 'users', level: 'global'
      end

      context 'for snippet_titles scope' do
        before do
          create(:personal_snippet, :public, title: 'awesome snippet', content: 'snippet content')

          get api(endpoint, user), params: { scope: 'snippet_titles', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/snippets'

        it_behaves_like 'apdex recorded', scope: 'snippet_titles', level: 'global'

        describe 'pagination' do
          before do
            create(:personal_snippet, :public, title: 'another snippet', content: 'snippet content')
          end

          include_examples 'pagination', scope: :snippet_titles
        end
      end

      context 'for ai_workflows scope' do
        let(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

        it 'is successful' do
          get api(endpoint, oauth_access_token: oauth_token), params: { scope: 'milestones', search: 'awesome' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'global search is disabled for the given scope' do
        it 'returns forbidden response' do
          allow_next_instance_of(SearchService) do |instance|
            allow(instance).to receive(:global_search_enabled_for_scope?).and_return false
          end
          get api(endpoint, user), params: { search: 'awesome', scope: 'issues' }
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'global search is enabled for the given scope' do
        it 'returns forbidden response' do
          allow_next_instance_of(SearchService) do |instance|
            allow(instance).to receive(:global_search_enabled_for_scope?).and_return true
          end
          get api(endpoint, user), params: { search: 'awesome', scope: 'issues' }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'global snippet search is disabled' do
        it 'returns forbidden response' do
          stub_application_setting(global_search_snippet_titles_enabled: false)
          get api(endpoint, user), params: { search: 'awesome', scope: 'snippet_titles' }
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'global snippet search is enabled' do
        it 'returns ok response' do
          stub_application_setting(global_search_snippet_titles_enabled: true)
          get api(endpoint, user), params: { search: 'awesome', scope: 'snippet_titles' }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it 'increments the custom search sli error rate with error false if no error occurred' do
        expect(Gitlab::Metrics::GlobalSearchSlis).to receive(:record_error_rate).with(
          error: false,
          search_scope: 'issues',
          search_type: 'basic',
          search_level: 'global'
        )

        get api(endpoint, user), params: { scope: 'issues', search: 'john doe' }
      end

      it 'increments the custom search sli error rate with error true if an error occurred' do
        allow_next_instance_of(SearchService) do |service|
          allow(service).to receive(:search_results).and_raise(ActiveRecord::QueryCanceled)
        end

        expect(Gitlab::Metrics::GlobalSearchSlis).to receive(:record_error_rate).with(
          error: true,
          search_scope: 'issues',
          search_type: 'basic',
          search_level: 'global'
        )

        get api(endpoint, user), params: { scope: 'issues', search: 'john doe' }
      end

      it 'sets global search information for logging' do
        expect(Gitlab::Instrumentation::GlobalSearchApi).to receive(:set_information).with(
          type: 'basic',
          level: 'global',
          scope: 'issues',
          search_duration_s: a_kind_of(Numeric)
        )

        get api(endpoint, user), params: { scope: 'issues', search: 'john doe' }
      end
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
      let(:current_user) { user }

      def request
        get api(endpoint, current_user), params: { scope: 'users', search: 'foo@bar.com' }
      end
    end

    context 'when request exceeds the rate limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
      before do
        stub_application_setting(search_rate_limit: 1)
      end

      it 'allows user whose username is in the allowlist' do
        stub_application_setting(search_rate_limit_allowlist: [user.username])

        get api(endpoint, user), params: { scope: 'users', search: 'foo@bar.com' }
        get api(endpoint, user), params: { scope: 'users', search: 'foo@bar.com' }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe "GET /groups/:id/search" do
    let(:endpoint) { "/groups/#{group.id}/-/search" }

    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api(endpoint), params: { scope: 'projects', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api(endpoint, user), params: { scope: 'unsupported', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api(endpoint, user), params: { search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when group does not exist' do
      it 'returns 404 error' do
        get api('/groups/0/search', user), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does can not see the group' do
      it 'returns 404 error' do
        private_group = create(:group, :private)

        get api("/groups/#{private_group.id}/search", user), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with correct params' do
      context 'for projects scope' do
        before do
          get api(endpoint, user), params: { scope: 'projects', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'

        it_behaves_like 'pagination', scope: :projects

        it_behaves_like 'apdex recorded', scope: 'projects', level: 'group'
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'

        it_behaves_like 'apdex recorded', scope: 'issues', level: 'group'

        it_behaves_like 'issues orderable by created_at'

        describe 'pagination' do
          before do
            create(:issue, project: project, title: 'another issue')
          end

          include_examples 'pagination', scope: :issues
        end
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api(endpoint, user), params: { scope: 'merge_requests', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'

        it_behaves_like 'apdex recorded', scope: 'merge_requests', level: 'group'

        it_behaves_like 'merge_requests orderable by created_at'

        describe 'pagination' do
          before do
            create(:merge_request, source_project: repo_project, title: 'another mr', target_branch: 'another_branch')
          end

          include_examples 'pagination', scope: :merge_requests
        end
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')

          get api(endpoint, user), params: { scope: 'milestones', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'

        it_behaves_like 'apdex recorded', scope: 'milestones', level: 'group'

        describe 'pagination' do
          before do
            create(:milestone, project: project, title: 'another milestone')
          end

          include_examples 'pagination', scope: :milestones
        end
      end

      context 'for milestones scope with group path as id' do
        before do
          another_project = create(:project, :public)
          create(:milestone, project: project, title: 'awesome milestone')
          create(:milestone, project: another_project, title: 'awesome milestone other project')

          get api("/groups/#{CGI.escape(group.full_path)}/search", user), params: { scope: 'milestones', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
      end

      context 'for users scope' do
        before do
          user = create(:user, name: 'billy')
          create(:group_member, :developer, user: user, group: group)

          get api(endpoint, user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'

        it_behaves_like 'apdex recorded', scope: 'users', level: 'group'

        describe 'pagination' do
          before do
            create(:group_member, :developer, group: group)
          end

          include_examples 'pagination', scope: :users
        end
      end

      context 'for users scope with group path as id' do
        before do
          user1 = create(:user, name: 'billy')
          create(:group_member, :developer, user: user1, group: group)

          get api("/groups/#{CGI.escape(group.full_path)}/search", user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
        let(:current_user) { user }

        def request
          get api(endpoint, current_user), params: { scope: 'users', search: 'foo@bar.com' }
        end
      end

      context 'when request exceeds the rate limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
        before do
          stub_application_setting(search_rate_limit: 1)
        end

        it 'allows user whose username is in the allowlist' do
          stub_application_setting(search_rate_limit_allowlist: [user.username])

          get api(endpoint, user), params: { scope: 'users', search: 'foo@bar.com' }
          get api(endpoint, user), params: { scope: 'users', search: 'foo@bar.com' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe "GET /projects/:id/search" do
    let(:endpoint) { "/projects/#{project.id}/search" }

    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api(endpoint), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api(endpoint, user), params: { scope: 'unsupported', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api(endpoint, user), params: { search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when user does not have permissions for scope' do
      it 'returns an empty array' do
        project.project_feature.update!(issues_access_level: Gitlab::VisibilityLevel::PRIVATE)

        get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }

        expect(json_response).to be_empty
      end
    end

    context 'when project does not exist' do
      it 'returns 404 error' do
        get api('/projects/0/search', user), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user can not see the project' do
      it 'returns 404 error' do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with correct params' do
      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'

        it_behaves_like 'issues orderable by created_at'

        it_behaves_like 'apdex recorded', scope: 'issues', level: 'project'

        describe 'pagination' do
          before do
            create(:issue, project: project, title: 'another issue')
          end

          include_examples 'pagination', scope: :issues
        end
      end

      context 'when requesting basic search' do
        it 'passes the parameter to search service' do
          expect(SearchService).to receive(:new).with(user, hash_including(search_type: 'basic'))

          get api(endpoint, user), params: { scope: 'issues', search: 'awesome', search_type: 'basic' }
        end
      end

      context 'for merge_requests scope' do
        let(:endpoint) { "/projects/#{repo_project.id}/search" }

        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api(endpoint, user), params: { scope: 'merge_requests', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'

        it_behaves_like 'merge_requests orderable by created_at'

        it_behaves_like 'apdex recorded', scope: 'merge_requests', level: 'project'

        describe 'pagination' do
          before do
            create(:merge_request, source_project: repo_project, title: 'another mr', target_branch: 'another_branch')
          end

          include_examples 'pagination', scope: :merge_requests
        end
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')
        end

        context 'when user can read milestones' do
          before do
            get api(endpoint, user), params: { scope: 'milestones', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'

          it_behaves_like 'apdex recorded', scope: 'milestones', level: 'project'

          describe 'pagination' do
            before do
              create(:milestone, project: project, title: 'another milestone')
            end

            include_examples 'pagination', scope: :milestones
          end
        end

        context 'when user cannot read project milestones' do
          before do
            project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
            project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
          end

          it 'returns empty array' do
            get api(endpoint, user), params: { scope: 'milestones', search: 'awesome' }

            milestones = json_response

            expect(milestones).to be_empty
          end
        end
      end

      context 'for users scope' do
        before do
          user1 = create(:user, name: 'billy')
          create(:project_member, :developer, user: user1, project: project)

          get api(endpoint, user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'

        it_behaves_like 'apdex recorded', scope: 'users', level: 'project'

        describe 'pagination' do
          before do
            create(:project_member, :developer, project: project)
          end

          include_examples 'pagination', scope: :users
        end
      end

      context 'for notes scope' do
        before do
          create(:note_on_merge_request, project: project, note: 'awesome note')

          get api(endpoint, user), params: { scope: 'notes', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/notes'

        it_behaves_like 'apdex recorded', scope: 'notes', level: 'project'

        describe 'pagination' do
          before do
            mr = create(:merge_request, source_project: project, target_branch: 'another_branch')
            create(:note, project: project, noteable: mr, note: 'another note')
          end

          include_examples 'pagination', scope: :notes
        end
      end

      context 'for wiki_blobs scope' do
        let(:wiki) { create(:project_wiki, project: project) }

        before do
          create(:wiki_page, wiki: wiki, title: 'home', content: "Awesome page")

          get api(endpoint, user), params: { scope: 'wiki_blobs', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/wiki_blobs'

        it_behaves_like 'apdex recorded', scope: 'wiki_blobs', level: 'project'

        describe 'pagination' do
          before do
            create(:wiki_page, wiki: wiki, title: 'home 2', content: 'Another page')
          end

          include_examples 'pagination', scope: :wiki_blobs, search: 'page'
        end
      end

      context 'for commits scope' do
        let(:endpoint) { "/projects/#{repo_project.id}/search" }

        before do
          get api(endpoint, user), params: { scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'

        it_behaves_like 'pagination', scope: :commits, search: 'merge'

        it_behaves_like 'apdex recorded', scope: 'commits', level: 'project'

        describe 'pipeline visibility' do
          shared_examples 'pipeline information visible' do
            it 'contains status and last_pipeline' do
              request

              expect(json_response[0]['status']).to eq 'success'
              expect(json_response[0]['last_pipeline']).not_to be_nil
            end
          end

          shared_examples 'pipeline information not visible' do
            it 'does not contain status and last_pipeline' do
              request

              expect(json_response[0]['status']).to be_nil
              expect(json_response[0]['last_pipeline']).to be_nil
            end
          end

          let(:request) { get api(endpoint, user), params: { scope: 'commits', search: repo_project.commit.sha } }

          before do
            create(:ci_pipeline, :success, project: repo_project, sha: repo_project.commit.sha)
          end

          context 'with non public pipeline' do
            let_it_be(:repo_project) do
              create(:project, :public, :repository, public_builds: false, group: group)
            end

            context 'user is project member with reporter role or above' do
              before do
                repo_project.add_reporter(user)
              end

              it_behaves_like 'pipeline information visible'
            end

            context 'user is project member with guest role' do
              before do
                repo_project.add_guest(user)
              end

              it_behaves_like 'pipeline information not visible'
            end

            context 'user is not project member' do
              let_it_be(:user) { create(:user) }

              it_behaves_like 'pipeline information not visible'
            end
          end

          context 'with public pipeline' do
            let_it_be(:repo_project) do
              create(:project, :public, :repository, public_builds: true, group: group)
            end

            context 'user is project member with reporter role or above' do
              before do
                repo_project.add_reporter(user)
              end

              it_behaves_like 'pipeline information visible'
            end

            context 'user is project member with guest role' do
              before do
                repo_project.add_guest(user)
              end

              it_behaves_like 'pipeline information visible'
            end

            context 'user is not project member' do
              let_it_be(:user) { create(:user) }

              it_behaves_like 'pipeline information visible'

              context 'when CI/CD is set to only project members' do
                before do
                  repo_project.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
                end

                it_behaves_like 'pipeline information not visible'
              end
            end
          end
        end
      end

      context 'for commits scope with project path as id' do
        before do
          get api("/projects/#{CGI.escape(repo_project.full_path)}/search", user), params: { scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'

        it_behaves_like 'apdex recorded', scope: 'commits', level: 'project'
      end

      context 'for blobs scope' do
        let(:endpoint) { "/projects/#{repo_project.id}/search" }

        before do
          get api(endpoint, user), params: { scope: 'blobs', search: 'monitors' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs', size: 2

        it_behaves_like 'pagination', scope: :blobs, search: 'monitors'

        it_behaves_like 'apdex recorded', scope: 'blobs', level: 'project'

        context 'filters' do
          it 'by filename' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'mon filename:PROCESS.md' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(2)
            expect(json_response.first['path']).to eq('PROCESS.md')
            expect(json_response.first['filename']).to eq('PROCESS.md')
          end

          it 'by path' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'mon path:markdown' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(8)
          end

          it 'by extension' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'mon extension:md' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(11)
          end

          it 'by ref' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'This file is used in tests for ci_environments_status', ref: 'pages-deploy' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
          end
        end
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :search_rate_limit do
        let(:current_user) { user }

        def request
          get api(endpoint, current_user), params: { scope: 'users', search: 'foo@bar.com' }
        end
      end

      context 'when request exceeds the rate limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
        before do
          stub_application_setting(search_rate_limit: 1)
        end

        it 'allows user whose username is in the allowlist' do
          stub_application_setting(search_rate_limit_allowlist: [user.username])

          get api(endpoint, user), params: { scope: 'users', search: 'foo@bar.com' }
          get api(endpoint, user), params: { scope: 'users', search: 'foo@bar.com' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
