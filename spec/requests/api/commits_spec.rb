require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:guest) { create(:project_member, :guest, user: user2, project: project) }
  let!(:note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
  let!(:another_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'another comment on a commit') }

  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/repository/commits" do
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

        expect(json_response.size).to eq(commits.size - 1)
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
  end

  describe "GET /projects:id/repository/commits/:sha" do
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
        expect(json_response['status']).to be_nil
      end
    end

    context "unauthorized user" do
      it "does not return the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}")
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "GET /projects:id/repository/commits/:sha/diff" do
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

  describe 'GET /projects:id/repository/commits/:sha/comments' do
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

  describe 'POST /projects:id/repository/commits/:sha/comments' do
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
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment', path: project.repository.commit.raw_diffs.first.new_path, line: 7, line_type: 'new'
        expect(response).to have_http_status(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to eq(project.repository.commit.raw_diffs.first.new_path)
        expect(json_response['line']).to eq(7)
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
