require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:guest) { create(:project_member, user: user2, project: project, access_level: ProjectMember::GUEST) }
  let!(:note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
  let!(:another_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'another comment on a commit') }

  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/repository/commits" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/commits", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(project.repository.commit.id)
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/commits")
        expect(response.status).to eq(401)
      end
    end
  end

  describe "GET /projects:id/repository/commits/:sha" do
    context "authorized user" do
      it "should return a commit by sha" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['id']).to eq(project.repository.commit.id)
        expect(json_response['title']).to eq(project.repository.commit.title)
      end

      it "should return a 404 error if not found" do
        get api("/projects/#{project.id}/repository/commits/invalid_sha", user)
        expect(response.status).to eq(404)
      end

      it "should return not_found for CI status" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['status']).to eq('not_found')
      end

      it "should return status for CI" do
        ci_commit = project.ensure_ci_commit(project.repository.commit.sha)
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['status']).to eq(ci_commit.status)
      end
    end

    context "unauthorized user" do
      it "should not return the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}")
        expect(response.status).to eq(401)
      end
    end
  end

  describe "GET /projects:id/repository/commits/:sha/diff" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return the diff of the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(json_response.length).to be >= 1
        expect(json_response.first.keys).to include "diff"
      end

      it "should return a 404 error if invalid commit" do
        get api("/projects/#{project.id}/repository/commits/invalid_sha/diff", user)
        expect(response.status).to eq(404)
      end
    end

    context "unauthorized user" do
      it "should not return the diff of the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff")
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects:id/repository/commits/:sha/comments' do
    context 'authorized user' do
      it 'should return merge_request comments' do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['note']).to eq('a comment on a commit')
        expect(json_response.first['author']['id']).to eq(user.id)
      end

      it 'should return a 404 error if merge_request_id not found' do
        get api("/projects/#{project.id}/repository/commits/1234ab/comments", user)
        expect(response.status).to eq(404)
      end
    end

    context 'unauthorized user' do
      it 'should not return the diff of the selected commit' do
        get api("/projects/#{project.id}/repository/commits/1234ab/comments")
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST /projects:id/repository/commits/:sha/comments' do
    context 'authorized user' do
      it 'should return comment' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment'
        expect(response.status).to eq(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to be_nil
        expect(json_response['line']).to be_nil
        expect(json_response['line_type']).to be_nil
      end

      it 'should return the inline comment' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment', path: project.repository.commit.diffs.first.new_path, line: 7, line_type: 'new'
        expect(response.status).to eq(201)
        expect(json_response['note']).to eq('My comment')
        expect(json_response['path']).to eq(project.repository.commit.diffs.first.new_path)
        expect(json_response['line']).to eq(7)
        expect(json_response['line_type']).to eq('new')
      end

      it 'should return 400 if note is missing' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        expect(response.status).to eq(400)
      end

      it 'should return 404 if note is attached to non existent commit' do
        post api("/projects/#{project.id}/repository/commits/1234ab/comments", user), note: 'My comment'
        expect(response.status).to eq(404)
      end
    end

    context 'unauthorized user' do
      it 'should not return the diff of the selected commit' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments")
        expect(response.status).to eq(401)
      end
    end
  end
end
