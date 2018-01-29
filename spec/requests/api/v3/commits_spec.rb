require 'spec_helper'
require 'mime/types'

describe API::V3::Commits do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }
  let!(:guest) { create(:project_member, :guest, user: user2, project: project) }
  let!(:note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
  let!(:another_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'another comment on a commit') }

  before { project.add_reporter(user) }

  describe "List repository commits" do
    context "authorized user" do
      before { project.add_reporter(user2) }

      it "returns project commits" do
        commit = project.repository.commit
        get v3_api("/projects/#{project.id}/repository/commits", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(commit.id)
        expect(json_response.first['committer_name']).to eq(commit.committer_name)
        expect(json_response.first['committer_email']).to eq(commit.committer_email)
      end
    end

    context "unauthorized user" do
      it "does not return project commits" do
        get v3_api("/projects/#{project.id}/repository/commits")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "since optional parameter" do
      it "returns project commits since provided parameter" do
        commits = project.repository.commits("master", limit: 2)
        since = commits.second.created_at

        get v3_api("/projects/#{project.id}/repository/commits?since=#{since.utc.iso8601}", user)

        expect(json_response.size).to eq 2
        expect(json_response.first["id"]).to eq(commits.first.id)
        expect(json_response.second["id"]).to eq(commits.second.id)
      end
    end

    context "until optional parameter" do
      it "returns project commits until provided parameter" do
        commits = project.repository.commits("master", limit: 20)
        before = commits.second.created_at

        get v3_api("/projects/#{project.id}/repository/commits?until=#{before.utc.iso8601}", user)

        if commits.size == 20
          expect(json_response.size).to eq(20)
        else
          expect(json_response.size).to eq(commits.size - 1)
        end

        expect(json_response.first["id"]).to eq(commits.second.id)
        expect(json_response.second["id"]).to eq(commits.third.id)
      end
    end

    context "invalid xmlschema date parameters" do
      it "returns an invalid parameter error message" do
        get v3_api("/projects/#{project.id}/repository/commits?since=invalid-date", user)

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('since is invalid')
      end
    end

    context "path optional parameter" do
      it "returns project commits matching provided path parameter" do
        path = 'files/ruby/popen.rb'

        get v3_api("/projects/#{project.id}/repository/commits?path=#{path}", user)

        expect(json_response.size).to eq(3)
        expect(json_response.first["id"]).to eq("570e7b2abdd848b95f2f578043fc23bd6f6fd24d")
      end
    end
  end

  describe "POST /projects/:id/repository/commits" do
    let!(:url) { "/projects/#{project.id}/repository/commits" }

    it 'returns a 403 unauthorized for user without permissions' do
      post v3_api(url, user2)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'returns a 400 bad request if no params are given' do
      post v3_api(url, user)

      expect(response).to have_gitlab_http_status(400)
    end

    describe 'create' do
      let(:message) { 'Created file' }
      let!(:invalid_c_params) do
        {
          branch_name: 'master',
          commit_message: message,
          actions: [
            {
              action: 'create',
              file_path: 'files/ruby/popen.rb',
              content: 'puts 8'
            }
          ]
        }
      end
      let!(:valid_c_params) do
        {
          branch_name: 'master',
          commit_message: message,
          actions: [
            {
              action: 'create',
              file_path: 'foo/bar/baz.txt',
              content: 'puts 8'
            }
          ]
        }
      end

      it 'a new file in project repo' do
        post v3_api(url, user), valid_c_params

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq(message)
        expect(json_response['committer_name']).to eq(user.name)
        expect(json_response['committer_email']).to eq(user.email)
      end

      it 'returns a 400 bad request if file exists' do
        post v3_api(url, user), invalid_c_params

        expect(response).to have_gitlab_http_status(400)
      end

      context 'with project path containing a dot in URL' do
        let!(:user) { create(:user, username: 'foo.bar') }
        let(:url) { "/projects/#{CGI.escape(project.full_path)}/repository/commits" }

        it 'a new file in project repo' do
          post v3_api(url, user), valid_c_params

          expect(response).to have_gitlab_http_status(201)
        end
      end
    end

    describe 'delete' do
      let(:message) { 'Deleted file' }
      let!(:invalid_d_params) do
        {
          branch_name: 'markdown',
          commit_message: message,
          actions: [
            {
              action: 'delete',
              file_path: 'doc/api/projects.md'
            }
          ]
        }
      end
      let!(:valid_d_params) do
        {
          branch_name: 'markdown',
          commit_message: message,
          actions: [
            {
              action: 'delete',
              file_path: 'doc/api/users.md'
            }
          ]
        }
      end

      it 'an existing file in project repo' do
        post v3_api(url, user), valid_d_params

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file does not exist' do
        post v3_api(url, user), invalid_d_params

        expect(response).to have_gitlab_http_status(400)
      end
    end

    describe 'move' do
      let(:message) { 'Moved file' }
      let!(:invalid_m_params) do
        {
          branch_name: 'feature',
          commit_message: message,
          actions: [
            {
              action: 'move',
              file_path: 'CHANGELOG',
              previous_path: 'VERSION',
              content: '6.7.0.pre'
            }
          ]
        }
      end
      let!(:valid_m_params) do
        {
          branch_name: 'feature',
          commit_message: message,
          actions: [
            {
              action: 'move',
              file_path: 'VERSION.txt',
              previous_path: 'VERSION',
              content: '6.7.0.pre'
            }
          ]
        }
      end

      it 'an existing file in project repo' do
        post v3_api(url, user), valid_m_params

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file does not exist' do
        post v3_api(url, user), invalid_m_params

        expect(response).to have_gitlab_http_status(400)
      end
    end

    describe 'update' do
      let(:message) { 'Updated file' }
      let!(:invalid_u_params) do
        {
          branch_name: 'master',
          commit_message: message,
          actions: [
            {
              action: 'update',
              file_path: 'foo/bar.baz',
              content: 'puts 8'
            }
          ]
        }
      end
      let!(:valid_u_params) do
        {
          branch_name: 'master',
          commit_message: message,
          actions: [
            {
              action: 'update',
              file_path: 'files/ruby/popen.rb',
              content: 'puts 8'
            }
          ]
        }
      end

      it 'an existing file in project repo' do
        post v3_api(url, user), valid_u_params

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file does not exist' do
        post v3_api(url, user), invalid_u_params

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context "multiple operations" do
      let(:message) { 'Multiple actions' }
      let!(:invalid_mo_params) do
        {
          branch_name: 'master',
          commit_message: message,
          actions: [
            {
              action: 'create',
              file_path: 'files/ruby/popen.rb',
              content: 'puts 8'
            },
            {
              action: 'delete',
              file_path: 'doc/v3_api/projects.md'
            },
            {
              action: 'move',
              file_path: 'CHANGELOG',
              previous_path: 'VERSION',
              content: '6.7.0.pre'
            },
            {
              action: 'update',
              file_path: 'foo/bar.baz',
              content: 'puts 8'
            }
          ]
        }
      end
      let!(:valid_mo_params) do
        {
          branch_name: 'master',
          commit_message: message,
          actions: [
            {
              action: 'create',
              file_path: 'foo/bar/baz.txt',
              content: 'puts 8'
            },
            {
              action: 'delete',
              file_path: 'Gemfile.zip'
            },
            {
              action: 'move',
              file_path: 'VERSION.txt',
              previous_path: 'VERSION',
              content: '6.7.0.pre'
            },
            {
              action: 'update',
              file_path: 'files/ruby/popen.rb',
              content: 'puts 8'
            }
          ]
        }
      end

      it 'are commited as one in project repo' do
        post v3_api(url, user), valid_mo_params

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'return a 400 bad request if there are any issues' do
        post v3_api(url, user), invalid_mo_params

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  describe "Get a single commit" do
    context "authorized user" do
      it "returns a commit by sha" do
        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(project.repository.commit.id)
        expect(json_response['title']).to eq(project.repository.commit.title)
        expect(json_response['stats']['additions']).to eq(project.repository.commit.stats.additions)
        expect(json_response['stats']['deletions']).to eq(project.repository.commit.stats.deletions)
        expect(json_response['stats']['total']).to eq(project.repository.commit.stats.total)
      end

      it "returns a 404 error if not found" do
        get v3_api("/projects/#{project.id}/repository/commits/invalid_sha", user)
        expect(response).to have_gitlab_http_status(404)
      end

      it "returns nil for commit without CI" do
        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to be_nil
      end

      it "returns status for CI" do
        pipeline = project.pipelines.create(source: :push, ref: 'master', sha: project.repository.commit.sha, protected: false)
        pipeline.update(status: 'success')

        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq(pipeline.status)
      end

      it "returns status for CI when pipeline is created" do
        project.pipelines.create(source: :push, ref: 'master', sha: project.repository.commit.sha, protected: false)

        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['status']).to eq("created")
      end

      context 'when stat param' do
        let(:project_id) { project.id }
        let(:commit_id) { project.repository.commit.id }
        let(:route) { "/projects/#{project_id}/repository/commits/#{commit_id}" }

        it 'is not present return stats by default' do
          get v3_api(route, user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to include 'stats'
        end

        it "is false it does not include stats" do
          get v3_api(route, user), stats: false

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).not_to include 'stats'
        end

        it "is true it includes stats" do
          get v3_api(route, user), stats: true

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to include 'stats'
        end
      end
    end

    context "unauthorized user" do
      it "does not return the selected commit" do
        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}")
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe "Get the diff of a commit" do
    context "authorized user" do
      before { project.add_reporter(user2) }

      it "returns the diff of the selected commit" do
        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff", user)
        expect(response).to have_gitlab_http_status(200)

        expect(json_response).to be_an Array
        expect(json_response.length).to be >= 1
        expect(json_response.first.keys).to include "diff"
      end

      it "returns a 404 error if invalid commit" do
        get v3_api("/projects/#{project.id}/repository/commits/invalid_sha/diff", user)
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "unauthorized user" do
      it "does not return the diff of the selected commit" do
        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff")
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'Get the comments of a commit' do
    context 'authorized user' do
      it 'returns merge_request comments' do
        get v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['note']).to eq('a comment on a commit')
        expect(json_response.first['author']['id']).to eq(user.id)
      end

      it 'returns a 404 error if merge_request_id not found' do
        get v3_api("/projects/#{project.id}/repository/commits/1234ab/comments", user)
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'unauthorized user' do
      it 'does not return the diff of the selected commit' do
        get v3_api("/projects/#{project.id}/repository/commits/1234ab/comments")
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'POST :id/repository/commits/:sha/cherry_pick' do
    let(:master_pickable_commit)  { project.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }

    context 'authorized user' do
      it 'cherry picks a commit' do
        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick", user), branch: 'master'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq(master_pickable_commit.title)
        expect(json_response['message']).to eq(master_pickable_commit.cherry_pick_message(user))
        expect(json_response['author_name']).to eq(master_pickable_commit.author_name)
        expect(json_response['committer_name']).to eq(user.name)
      end

      it 'returns 400 if commit is already included in the target branch' do
        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick", user), branch: 'markdown'

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to include('Sorry, we cannot cherry-pick this commit automatically.')
      end

      it 'returns 400 if you are not allowed to push to the target branch' do
        project.add_developer(user2)
        protected_branch = create(:protected_branch, project: project, name: 'feature')

        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick", user2), branch: protected_branch.name

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('You are not allowed to push into this branch')
      end

      it 'returns 400 for missing parameters' do
        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick", user)

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('branch is missing')
      end

      it 'returns 404 if commit is not found' do
        post v3_api("/projects/#{project.id}/repository/commits/abcd0123/cherry_pick", user), branch: 'master'

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Commit Not Found')
      end

      it 'returns 404 if branch is not found' do
        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick", user), branch: 'foo'

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Branch Not Found')
      end

      it 'returns 400 for missing parameters' do
        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick", user)

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('branch is missing')
      end
    end

    context 'unauthorized user' do
      it 'does not cherry pick the commit' do
        post v3_api("/projects/#{project.id}/repository/commits/#{master_pickable_commit.id}/cherry_pick"), branch: 'master'

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'Post comment to commit' do
    context 'authorized user' do
      it 'returns comment' do
        post v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment'
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to be_nil
        expect(json_response['line']).to be_nil
        expect(json_response['line_type']).to be_nil
      end

      it 'returns the inline comment' do
        post v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment', path: project.repository.commit.raw_diffs.first.new_path, line: 1, line_type: 'new'

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to eq(project.repository.commit.raw_diffs.first.new_path)
        expect(json_response['line']).to eq(1)
        expect(json_response['line_type']).to eq('new')
      end

      it 'returns 400 if note is missing' do
        post v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 404 if note is attached to non existent commit' do
        post v3_api("/projects/#{project.id}/repository/commits/1234ab/comments", user), note: 'My comment'
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'unauthorized user' do
      it 'does not return the diff of the selected commit' do
        post v3_api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments")
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
