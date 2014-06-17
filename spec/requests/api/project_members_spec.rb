require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let(:users_project) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let(:users_project2) { create(:users_project, user: user3, project: project, project_access: UsersProject::DEVELOPER) }

  describe "GET /projects/:id/members" do
    before { users_project }
    before { users_project2 }

    it "should return project team members" do
      get api("/projects/#{project.id}/members", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.count.should == 2
      json_response.map { |u| u['username'] }.should include user.username
    end

    it "finds team members with query string" do
      get api("/projects/#{project.id}/members", user), query: user.username
      response.status.should == 200
      json_response.should be_an Array
      json_response.count.should == 1
      json_response.first['username'].should == user.username
    end

    it "should return a 404 error if id not found" do
      get api("/projects/9999/members", user)
      response.status.should == 404
    end
  end

  describe "GET /projects/:id/members/:user_id" do
    before { users_project }

    it "should return project team member" do
      get api("/projects/#{project.id}/members/#{user.id}", user)
      response.status.should == 200
      json_response['username'].should == user.username
      json_response['access_level'].should == UsersProject::MASTER
    end

    it "should return a 404 error if user id not found" do
      get api("/projects/#{project.id}/members/1234", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/members" do
    it "should add user to project team" do
      expect {
        post api("/projects/#{project.id}/members", user), user_id: user2.id,
          access_level: UsersProject::DEVELOPER
      }.to change { UsersProject.count }.by(1)

      response.status.should == 201
      json_response['username'].should == user2.username
      json_response['access_level'].should == UsersProject::DEVELOPER
    end

    it "should return a 201 status if user is already project member" do
      post api("/projects/#{project.id}/members", user), user_id: user2.id,
        access_level: UsersProject::DEVELOPER
      expect {
        post api("/projects/#{project.id}/members", user), user_id: user2.id,
          access_level: UsersProject::DEVELOPER
      }.not_to change { UsersProject.count }.by(1)

      response.status.should == 201
      json_response['username'].should == user2.username
      json_response['access_level'].should == UsersProject::DEVELOPER
    end

    it "should return a 400 error when user id is not given" do
      post api("/projects/#{project.id}/members", user), access_level: UsersProject::MASTER
      response.status.should == 400
    end

    it "should return a 400 error when access level is not given" do
      post api("/projects/#{project.id}/members", user), user_id: user2.id
      response.status.should == 400
    end

    it "should return a 422 error when access level is not known" do
      post api("/projects/#{project.id}/members", user), user_id: user2.id, access_level: 1234
      response.status.should == 422
    end
  end

  describe "PUT /projects/:id/members/:user_id" do
    before { users_project2 }

    it "should update project team member" do
      put api("/projects/#{project.id}/members/#{user3.id}", user), access_level: UsersProject::MASTER
      response.status.should == 200
      json_response['username'].should == user3.username
      json_response['access_level'].should == UsersProject::MASTER
    end

    it "should return a 404 error if user_id is not found" do
      put api("/projects/#{project.id}/members/1234", user), access_level: UsersProject::MASTER
      response.status.should == 404
    end

    it "should return a 400 error when access level is not given" do
      put api("/projects/#{project.id}/members/#{user3.id}", user)
      response.status.should == 400
    end

    it "should return a 422 error when access level is not known" do
      put api("/projects/#{project.id}/members/#{user3.id}", user), access_level: 123
      response.status.should == 422
    end
  end

  describe "DELETE /projects/:id/members/:user_id" do
    before { users_project }
    before { users_project2 }

    it "should remove user from project team" do
      expect {
        delete api("/projects/#{project.id}/members/#{user3.id}", user)
      }.to change { UsersProject.count }.by(-1)
    end

    it "should return 200 if team member is not part of a project" do
      delete api("/projects/#{project.id}/members/#{user3.id}", user)
      expect {
        delete api("/projects/#{project.id}/members/#{user3.id}", user)
      }.to_not change { UsersProject.count }.by(1)
    end

    it "should return 200 if team member already removed" do
      delete api("/projects/#{project.id}/members/#{user3.id}", user)
      delete api("/projects/#{project.id}/members/#{user3.id}", user)
      response.status.should == 200
    end

    it "should return 200 OK when the user was not member" do
      expect {
        delete api("/projects/#{project.id}/members/1000000", user)
      }.to change { UsersProject.count }.by(0)
      response.status.should == 200
      json_response['message'].should == "Access revoked"
      json_response['id'].should == 1000000
    end
  end
end
