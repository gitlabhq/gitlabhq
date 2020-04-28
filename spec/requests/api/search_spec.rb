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

  describe 'GET /search'  do
    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api('/search'), params: { scope: 'projects', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api('/search', user), params: { scope: 'unsupported', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api('/search', user), params: { search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with correct params' do
      context 'for projects scope' do
        before do
          get api('/search', user), params: { scope: 'projects', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api('/search', user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api('/search', user), params: { scope: 'merge_requests', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')
        end

        context 'when user can read project milestones' do
          before do
            get api('/search', user), params: { scope: 'milestones', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
        end

        context 'when user cannot read project milestones' do
          before do
            project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
            project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
          end

          it 'returns empty array' do
            get api('/search', user), params: { scope: 'milestones', search: 'awesome' }

            milestones = json_response

            expect(milestones).to be_empty
          end
        end
      end

      context 'for users scope' do
        before do
          create(:user, name: 'billy')

          get api('/search', user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'

        context 'when users search feature is disabled' do
          before do
            allow(Feature).to receive(:disabled?).with(:users_search, default_enabled: true).and_return(true)

            get api('/search', user), params: { scope: 'users', search: 'billy' }
          end

          it 'returns 400 error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'for snippet_titles scope' do
        before do
          create(:snippet, :public, title: 'awesome snippet', content: 'snippet content')

          get api('/search', user), params: { scope: 'snippet_titles', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/snippets'
      end
    end
  end

  describe "GET /groups/:id/search" do
    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api("/groups/#{group.id}/search"), params: { scope: 'projects', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api("/groups/#{group.id}/search", user), params: { scope: 'unsupported', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api("/groups/#{group.id}/search", user), params: { search: 'awesome' }

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
          get api("/groups/#{group.id}/search", user), params: { scope: 'projects', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api("/groups/#{group.id}/search", user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api("/groups/#{group.id}/search", user), params: { scope: 'merge_requests', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')

          get api("/groups/#{group.id}/search", user), params: { scope: 'milestones', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
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

          get api("/groups/#{group.id}/search", user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'

        context 'when users search feature is disabled' do
          before do
            allow(Feature).to receive(:disabled?).with(:users_search, default_enabled: true).and_return(true)

            get api("/groups/#{group.id}/search", user), params: { scope: 'users', search: 'billy' }
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
    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api("/projects/#{project.id}/search"), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api("/projects/#{project.id}/search", user), params: { scope: 'unsupported', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api("/projects/#{project.id}/search", user), params: { search: 'awesome' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when project does not exist' do
      it 'returns 404 error' do
        get api('/projects/0/search', user), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does can not see the project' do
      it 'returns 404 error' do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        get api("/projects/#{project.id}/search", user), params: { scope: 'issues', search: 'awesome' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with correct params' do
      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api("/projects/#{project.id}/search", user), params: { scope: 'issues', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api("/projects/#{repo_project.id}/search", user), params: { scope: 'merge_requests', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')
        end

        context 'when user can read milestones' do
          before do
            get api("/projects/#{project.id}/search", user), params: { scope: 'milestones', search: 'awesome' }
          end

          it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
        end

        context 'when user cannot read project milestones' do
          before do
            project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
            project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
          end

          it 'returns empty array' do
            get api("/projects/#{project.id}/search", user), params: { scope: 'milestones', search: 'awesome' }

            milestones = json_response

            expect(milestones).to be_empty
          end
        end
      end

      context 'for users scope' do
        before do
          user1 = create(:user, name: 'billy')
          create(:project_member, :developer, user: user1, project: project)

          get api("/projects/#{project.id}/search", user), params: { scope: 'users', search: 'billy' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/user/basics'

        context 'when users search feature is disabled' do
          before do
            allow(Feature).to receive(:disabled?).with(:users_search, default_enabled: true).and_return(true)

            get api("/projects/#{project.id}/search", user), params: { scope: 'users', search: 'billy' }
          end

          it 'returns 400 error' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'for notes scope' do
        before do
          create(:note_on_merge_request, project: project, note: 'awesome note')

          get api("/projects/#{project.id}/search", user), params: { scope: 'notes', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/notes'
      end

      context 'for wiki_blobs scope' do
        before do
          wiki = create(:project_wiki, project: project)
          create(:wiki_page, wiki: wiki, title: 'home', content: "Awesome page")

          get api("/projects/#{project.id}/search", user), params: { scope: 'wiki_blobs', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs'
      end

      context 'for commits scope' do
        before do
          get api("/projects/#{repo_project.id}/search", user), params: { scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'
      end

      context 'for commits scope with project path as id' do
        before do
          get api("/projects/#{CGI.escape(repo_project.full_path)}/search", user), params: { scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'
      end

      context 'for blobs scope' do
        before do
          get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'monitors' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs', size: 2

        context 'filters' do
          it 'by filename' do
            get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'mon filename:PROCESS.md' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(2)
            expect(json_response.first['path']).to eq('PROCESS.md')
            expect(json_response.first['filename']).to eq('PROCESS.md')
          end

          it 'by path' do
            get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'mon path:markdown' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(8)
          end

          it 'by extension' do
            get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'mon extension:md' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(11)
          end

          it 'by ref' do
            get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'This file is used in tests for ci_environments_status', ref: 'pages-deploy' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
          end
        end
      end
    end
  end
end
