require 'spec_helper'

describe API::Search do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  set(:project) { create(:project, :public, name: 'awesome project', group: group) }
  set(:repo_project) { create(:project, :public, :repository, group: group) }

  shared_examples 'response is correct' do |schema:, size: 1|
    it { expect(response).to have_gitlab_http_status(200) }
    it { expect(response).to match_response_schema(schema) }
    it { expect(response).to include_limited_pagination_headers }
    it { expect(json_response.size).to eq(size) }
  end

  describe 'GET /search'  do
    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api('/search'), scope: 'projects', search: 'awesome'

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api('/search', user), scope: 'unsupported', search: 'awesome'

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api('/search', user), search: 'awesome'

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'with correct params' do
      context 'for projects scope' do
        before do
          get api('/search', user), scope: 'projects', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api('/search', user), scope: 'issues', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api('/search', user), scope: 'merge_requests', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')

          get api('/search', user), scope: 'milestones', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
      end

      context 'for snippet_titles scope' do
        before do
          create(:snippet, :public, title: 'awesome snippet', content: 'snippet content')

          get api('/search', user), scope: 'snippet_titles', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/snippets'
      end

      context 'for snippet_blobs scope' do
        before do
          create(:snippet, :public, title: 'awesome snippet', content: 'snippet content')

          get api('/search', user), scope: 'snippet_blobs', search: 'content'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/snippets'
      end
    end
  end

  describe "GET /groups/:id/search" do
    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api("/groups/#{group.id}/search"), scope: 'projects', search: 'awesome'

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api("/groups/#{group.id}/search", user), scope: 'unsupported', search: 'awesome'

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api("/groups/#{group.id}/search", user), search: 'awesome'

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when group does not exist' do
      it 'returns 404 error' do
        get api('/groups/9999/search', user), scope: 'issues', search: 'awesome'

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user does can not see the group' do
      it 'returns 404 error' do
        private_group = create(:group, :private)

        get api("/groups/#{private_group.id}/search", user), scope: 'issues', search: 'awesome'

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with correct params' do
      context 'for projects scope' do
        before do
          get api("/groups/#{group.id}/search", user), scope: 'projects', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/projects'
      end

      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api("/groups/#{group.id}/search", user), scope: 'issues', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api("/groups/#{group.id}/search", user), scope: 'merge_requests', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')

          get api("/groups/#{group.id}/search", user), scope: 'milestones', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
      end

      context 'for milestones scope with group path as id' do
        before do
          another_project = create(:project, :public)
          create(:milestone, project: project, title: 'awesome milestone')
          create(:milestone, project: another_project, title: 'awesome milestone other project')

          get api("/groups/#{CGI.escape(group.full_path)}/search", user), scope: 'milestones', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
      end
    end
  end

  describe "GET /projects/:id/search" do
    context 'when user is not authenticated' do
      it 'returns 401 error' do
        get api("/projects/#{project.id}/search"), scope: 'issues', search: 'awesome'

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when scope is not supported' do
      it 'returns 400 error' do
        get api("/projects/#{project.id}/search", user), scope: 'unsupported', search: 'awesome'

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when scope is missing' do
      it 'returns 400 error' do
        get api("/projects/#{project.id}/search", user), search: 'awesome'

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when project does not exist' do
      it 'returns 404 error' do
        get api('/projects/9999/search', user), scope: 'issues', search: 'awesome'

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user does can not see the project' do
      it 'returns 404 error' do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        get api("/projects/#{project.id}/search", user), scope: 'issues', search: 'awesome'

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with correct params' do
      context 'for issues scope' do
        before do
          create(:issue, project: project, title: 'awesome issue')

          get api("/projects/#{project.id}/search", user), scope: 'issues', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/issues'
      end

      context 'for merge_requests scope' do
        before do
          create(:merge_request, source_project: repo_project, title: 'awesome mr')

          get api("/projects/#{repo_project.id}/search", user), scope: 'merge_requests', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/merge_requests'
      end

      context 'for milestones scope' do
        before do
          create(:milestone, project: project, title: 'awesome milestone')

          get api("/projects/#{project.id}/search", user), scope: 'milestones', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/milestones'
      end

      context 'for notes scope' do
        before do
          create(:note_on_merge_request, project: project, note: 'awesome note')

          get api("/projects/#{project.id}/search", user), scope: 'notes', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/notes'
      end

      context 'for wiki_blobs scope' do
        before do
          wiki = create(:project_wiki, project: project)
          create(:wiki_page, wiki: wiki, attrs: { title: 'home', content: "Awesome page" })

          get api("/projects/#{project.id}/search", user), scope: 'wiki_blobs', search: 'awesome'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs'
      end

      context 'for commits scope' do
        before do
          get api("/projects/#{repo_project.id}/search", user), scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'
      end

      context 'for commits scope with project path as id' do
        before do
          get api("/projects/#{CGI.escape(repo_project.full_path)}/search", user), scope: 'commits', search: '498214de67004b1da3d820901307bed2a68a8ef6'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details'
      end

      context 'for blobs scope' do
        before do
          get api("/projects/#{repo_project.id}/search", user), scope: 'blobs', search: 'monitors'
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs', size: 2
      end
    end
  end
end
