# frozen_string_literal: true

require 'spec_helper'

describe API::Search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :wiki_repo, :public, name: 'awesome project', group: group) }
  let_it_be(:repo_project) { create(:project, :public, :repository, group: group) }

  shared_examples 'response is correct' do |schema:, size: 1|
    it { expect(response).to have_gitlab_http_status(:ok) }
    it { expect(response).to match_response_schema(schema) }
    it { expect(response).to include_limited_pagination_headers }
    it { expect(json_response.size).to eq(size) }
  end

  shared_examples 'ping counters' do |scope:, search: ''|
    it 'increases usage ping searches counter' do
      expect(Gitlab::UsageDataCounters::SearchCounter).to receive(:count).with(:all_searches)

      get api(endpoint, user), params: { scope: scope, search: search }
    end
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

  describe 'GET /search' do
    let(:endpoint) { '/search' }

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

    context 'with correct params' do
      context 'for projects scope' do
        before do
          get api(endpoint, user), params: { scope: 'projects', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'

        it_behaves_like 'pagination', scope: :projects

        it_behaves_like 'ping counters', scope: :projects
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'

        it_behaves_like 'ping counters', scope: :issues

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

        it_behaves_like 'ping counters', scope: :merge_requests

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

        context 'when user can read project milestones' do
          before do
            get api(endpoint, user), params: { scope: 'milestones', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'

          it_behaves_like 'ping counters', scope: :milestones

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

        it_behaves_like 'ping counters', scope: :users

        context 'when users search feature is disabled' do
          before do
            stub_feature_flags(users_search: false)

            get api(endpoint, user), params: { scope: 'users', search: 'billy' }
          end

          it 'returns 400 error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'for snippet_titles scope' do
        before do
          create(:snippet, :public, title: 'awesome snippet', content: 'snippet content')

          get api(endpoint, user), params: { scope: 'snippet_titles', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/snippets'

        it_behaves_like 'ping counters', scope: :snippet_titles

        describe 'pagination' do
          before do
            create(:snippet, :public, title: 'another snippet', content: 'snippet content')
          end

          include_examples 'pagination', scope: :snippet_titles
        end
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

        it_behaves_like 'ping counters', scope: :projects
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api(endpoint, user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'

        it_behaves_like 'ping counters', scope: :issues

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

        it_behaves_like 'ping counters', scope: :merge_requests

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

        it_behaves_like 'ping counters', scope: :milestones

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

        it_behaves_like 'ping counters', scope: :users

        describe 'pagination' do
          before do
            create(:group_member, :developer, group: group)
          end

          include_examples 'pagination', scope: :users
        end

        context 'when users search feature is disabled' do
          before do
            stub_feature_flags(users_search: false)

            get api(endpoint, user), params: { scope: 'users', search: 'billy' }
          end

          it 'returns 400 error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
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

        it_behaves_like 'ping counters', scope: :issues

        describe 'pagination' do
          before do
            create(:issue, project: project, title: 'another issue')
          end

          include_examples 'pagination', scope: :issues
        end
      end

      context 'for merge_requests scope' do
        let(:endpoint) { "/projects/#{repo_project.id}/search" }

        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api(endpoint, user), params: { scope: 'merge_requests', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'

        it_behaves_like 'ping counters', scope: :merge_requests

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

          it_behaves_like 'ping counters', scope: :milestones

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

        it_behaves_like 'ping counters', scope: :users

        describe 'pagination' do
          before do
            create(:project_member, :developer, project: project)
          end

          include_examples 'pagination', scope: :users
        end

        context 'when users search feature is disabled' do
          before do
            stub_feature_flags(users_search: false)

            get api(endpoint, user), params: { scope: 'users', search: 'billy' }
          end

          it 'returns 400 error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'for notes scope' do
        before do
          create(:note_on_merge_request, project: project, note: 'awesome note')

          get api(endpoint, user), params: { scope: 'notes', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/notes'

        it_behaves_like 'ping counters', scope: :notes

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

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs'

        it_behaves_like 'ping counters', scope: :wiki_blobs

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

        it_behaves_like 'ping counters', scope: :commits
      end

      context 'for commits scope with project path as id' do
        before do
          get api("/projects/#{CGI.escape(repo_project.full_path)}/search", user), params: { scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'
      end

      context 'for blobs scope' do
        let(:endpoint) { "/projects/#{repo_project.id}/search" }

        before do
          get api(endpoint, user), params: { scope: 'blobs', search: 'monitors' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs', size: 2

        it_behaves_like 'pagination', scope: :blobs, search: 'monitors'

        it_behaves_like 'ping counters', scope: :blobs

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
    end
  end
end
