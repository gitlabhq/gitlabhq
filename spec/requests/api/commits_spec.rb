require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:guest) { create(:project_member, :guest, user: user2, project: project) }
  let!(:note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
  let!(:another_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'another comment on a commit') }

  before { project.team << [user, :reporter] }

  describe "List repository commits" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "returns project commits" do
        get api("/projects/#{project.id}/repository/commits", user)
        expect(response).to have_http_status(200)

        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(project.repository.commit.id)
      end
    end

    context "unauthorized user" do
      it "does not return project commits" do
        get api("/projects/#{project.id}/repository/commits")
        expect(response).to have_http_status(401)
      end
    end

    context "since optional parameter" do
      it "returns project commits since provided parameter" do
        commits = project.repository.commits("master")
        since = commits.second.created_at

        get api("/projects/#{project.id}/repository/commits?since=#{since.utc.iso8601}", user)

        expect(json_response.size).to eq 2
        expect(json_response.first["id"]).to eq(commits.first.id)
        expect(json_response.second["id"]).to eq(commits.second.id)
      end
    end

    context "until optional parameter" do
      it "returns project commits until provided parameter" do
        commits = project.repository.commits("master")
        before = commits.second.created_at

        get api("/projects/#{project.id}/repository/commits?until=#{before.utc.iso8601}", user)

        if commits.size >= 20
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
        get api("/projects/#{project.id}/repository/commits?since=invalid-date", user)

        expect(response).to have_http_status(400)
        expect(json_response['message']).to include "\"since\" must be a timestamp in ISO 8601 format"
      end
    end

    context "path optional parameter" do
      it "returns project commits matching provided path parameter" do
        path = 'files/ruby/popen.rb'

        get api("/projects/#{project.id}/repository/commits?path=#{path}", user)

        expect(json_response.size).to eq(3)
        expect(json_response.first["id"]).to eq("570e7b2abdd848b95f2f578043fc23bd6f6fd24d")
      end
    end
  end

  describe "Create a commit with multiple files and actions" do
    let!(:url) { "/projects/#{project.id}/repository/commits" }

    it 'returns a 403 unauthorized for user without permissions' do
      post api(url, user2)

      expect(response).to have_http_status(403)
    end

    it 'returns a 400 bad request if no params are given' do
      post api(url, user)

      expect(response).to have_http_status(400)
    end

    context :create do
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
        post api(url, user), valid_c_params

        expect(response).to have_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file exists' do
        post api(url, user), invalid_c_params

        expect(response).to have_http_status(400)
      end
    end

    context :delete do
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
        post api(url, user), valid_d_params

        expect(response).to have_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file does not exist' do
        post api(url, user), invalid_d_params

        expect(response).to have_http_status(400)
      end
    end

    context :move do
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
        post api(url, user), valid_m_params

        expect(response).to have_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file does not exist' do
        post api(url, user), invalid_m_params

        expect(response).to have_http_status(400)
      end
    end

    context :update do
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
        post api(url, user), valid_u_params

        expect(response).to have_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'returns a 400 bad request if file does not exist' do
        post api(url, user), invalid_u_params

        expect(response).to have_http_status(400)
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
              file_path: 'doc/api/projects.md'
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
        post api(url, user), valid_mo_params

        expect(response).to have_http_status(201)
        expect(json_response['title']).to eq(message)
      end

      it 'return a 400 bad request if there are any issues' do
        post api(url, user), invalid_mo_params

        expect(response).to have_http_status(400)
      end
    end
  end

  describe "Get a single commit" do
    context "authorized user" do
      it "returns a commit by sha" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['id']).to eq(project.repository.commit.id)
        expect(json_response['title']).to eq(project.repository.commit.title)
        expect(json_response['stats']['additions']).to eq(project.repository.commit.stats.additions)
        expect(json_response['stats']['deletions']).to eq(project.repository.commit.stats.deletions)
        expect(json_response['stats']['total']).to eq(project.repository.commit.stats.total)
      end

      it "returns a 404 error if not found" do
        get api("/projects/#{project.id}/repository/commits/invalid_sha", user)
        expect(response).to have_http_status(404)
      end

      it "returns nil for commit without CI" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['status']).to be_nil
      end

      it "returns status for CI" do
        pipeline = project.ensure_pipeline('master', project.repository.commit.sha)
        pipeline.update(status: 'success')

        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['status']).to eq(pipeline.status)
      end

      it "returns status for CI when pipeline is created" do
        project.ensure_pipeline('master', project.repository.commit.sha)

        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['status']).to eq("created")
      end
    end

    context "unauthorized user" do
      it "does not return the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}")
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "Get the diff of a commit" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "returns the diff of the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff", user)
        expect(response).to have_http_status(200)

        expect(json_response).to be_an Array
        expect(json_response.length).to be >= 1
        expect(json_response.first.keys).to include "diff"
      end

      it "returns a 404 error if invalid commit" do
        get api("/projects/#{project.id}/repository/commits/invalid_sha/diff", user)
        expect(response).to have_http_status(404)
      end
    end

    context "unauthorized user" do
      it "does not return the diff of the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff")
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'Get the comments of a commit' do
    context 'authorized user' do
      it 'returns merge_request comments' do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['note']).to eq('a comment on a commit')
        expect(json_response.first['author']['id']).to eq(user.id)
      end

      it 'returns a 404 error if merge_request_id not found' do
        get api("/projects/#{project.id}/repository/commits/1234ab/comments", user)
        expect(response).to have_http_status(404)
      end
    end

    context 'unauthorized user' do
      it 'does not return the diff of the selected commit' do
        get api("/projects/#{project.id}/repository/commits/1234ab/comments")
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'Post comment to commit' do
    context 'authorized user' do
      it 'returns comment' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment'
        expect(response).to have_http_status(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to be_nil
        expect(json_response['line']).to be_nil
        expect(json_response['line_type']).to be_nil
      end

      it 'returns the inline comment' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment', path: project.repository.commit.raw_diffs.first.new_path, line: 1, line_type: 'new'

        expect(response).to have_http_status(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to eq(project.repository.commit.raw_diffs.first.new_path)
        expect(json_response['line']).to eq(1)
        expect(json_response['line_type']).to eq('new')
      end

      it 'returns 400 if note is missing' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        expect(response).to have_http_status(400)
      end

      it 'returns 404 if note is attached to non existent commit' do
        post api("/projects/#{project.id}/repository/commits/1234ab/comments", user), note: 'My comment'
        expect(response).to have_http_status(404)
      end
    end

    context 'unauthorized user' do
      it 'does not return the diff of the selected commit' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments")
        expect(response).to have_http_status(401)
      end
    end
  end
end
