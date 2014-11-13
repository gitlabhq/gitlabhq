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

  before { project.team << [user, :reporter] }

  describe "GET /projects/:id/repository/commits" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return project commits" do
        get api("/projects/#{project.id}/repository/commits", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.first['id'].should == project.repository.commit.id
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.id}/repository/commits")
        response.status.should == 401
      end
    end
  end

  describe "GET /projects:id/repository/commits/:sha" do
    context "authorized user" do
      it "should return a commit by sha" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}", user)
        response.status.should == 200
        json_response['id'].should == project.repository.commit.id
        json_response['title'].should == project.repository.commit.title
      end

      it "should return a 404 error if not found" do
        get api("/projects/#{project.id}/repository/commits/invalid_sha", user)
        response.status.should == 404
      end
    end

    context "unauthorized user" do
      it "should not return the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}")
        response.status.should == 401
      end
    end
  end

  describe "GET /projects:id/repository/commits/:sha/diff" do
    context "authorized user" do
      before { project.team << [user2, :reporter] }

      it "should return the diff of the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.length.should >= 1
        json_response.first.keys.should include "diff"
      end

      it "should return a 404 error if invalid commit" do
        get api("/projects/#{project.id}/repository/commits/invalid_sha/diff", user)
        response.status.should == 404
      end
    end

    context "unauthorized user" do
      it "should not return the diff of the selected commit" do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/diff")
        response.status.should == 401
      end
    end
  end

  describe 'GET /projects:id/repository/commits/:sha/comments' do
    context 'authorized user' do
      it 'should return merge_request comments' do
        get api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['note'].should == 'a comment on a commit'
        json_response.first['author']['id'].should == user.id
      end

      it 'should return a 404 error if merge_request_id not found' do
        get api("/projects/#{project.id}/repository/commits/1234ab/comments", user)
        response.status.should == 404
      end
    end

    context 'unauthorized user' do
      it 'should not return the diff of the selected commit' do
        get api("/projects/#{project.id}/repository/commits/1234ab/comments")
        response.status.should == 401
      end
    end
  end

  describe 'POST /projects:id/repository/commits/:sha/comments' do
    context 'authorized user' do
      it 'should return comment' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment'
        response.status.should == 201
        json_response['note'].should == 'My comment'
        json_response['path'].should be_nil
        json_response['line'].should be_nil
        json_response['line_type'].should be_nil
      end

      it 'should return the inline comment' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user), note: 'My comment', path: project.repository.commit.diffs.first.new_path, line: 7, line_type: 'new'
        response.status.should == 201
        json_response['note'].should == 'My comment'
        json_response['path'].should == project.repository.commit.diffs.first.new_path
        json_response['line'].should == 7
        json_response['line_type'].should == 'new'
      end

      it 'should return 400 if note is missing' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments", user)
        response.status.should == 400
      end

      it 'should return 404 if note is attached to non existent commit' do
        post api("/projects/#{project.id}/repository/commits/1234ab/comments", user), note: 'My comment'
        response.status.should == 404
      end
    end

    context 'unauthorized user' do
      it 'should not return the diff of the selected commit' do
        post api("/projects/#{project.id}/repository/commits/#{project.repository.commit.id}/comments")
        response.status.should == 401
      end
    end
  end
end
