require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let!(:guest) { create(:users_project, user: user2, project: project, project_access: UsersProject::GUEST) }

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
end
