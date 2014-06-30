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
end
