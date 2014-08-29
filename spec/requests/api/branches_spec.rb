require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let!(:guest) { create(:users_project, user: user2, project: project, project_access: UsersProject::GUEST) }
  let!(:branch_name) { 'feature' }
  let!(:branch_sha) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

  describe "GET /projects/:id/repository/branches" do
    it "should return an array of project branches" do
      get api("/projects/#{project.id}/repository/branches", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.heads.sort_by(&:name).first.name
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    it "should return the branch information for a single branch" do
      get api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      response.status.should == 200

      json_response['name'].should == branch_name
      json_response['commit']['id'].should == branch_sha
      json_response['protected'].should == false
    end

    it "should return a 403 error if guest" do
      get api("/projects/#{project.id}/repository/branches", user2)
      response.status.should == 403
    end

    it "should return a 404 error if branch is not available" do
      get api("/projects/#{project.id}/repository/branches/unknown", user)
      response.status.should == 404
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/protect" do
    it "should protect a single branch" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
      response.status.should == 200

      json_response['name'].should == branch_name
      json_response['commit']['id'].should == branch_sha
      json_response['protected'].should == true
    end

    it "should return a 404 error if branch not found" do
      put api("/projects/#{project.id}/repository/branches/unknown/protect", user)
      response.status.should == 404
    end

    it "should return a 403 error if guest" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user2)
      response.status.should == 403
    end

    it "should return success when protect branch again" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
      response.status.should == 200
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/unprotect" do
    it "should unprotect a single branch" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      response.status.should == 200

      json_response['name'].should == branch_name
      json_response['commit']['id'].should == branch_sha
      json_response['protected'].should == false
    end

    it "should return success when unprotect branch" do
      put api("/projects/#{project.id}/repository/branches/unknown/unprotect", user)
      response.status.should == 404
    end

    it "should return success when unprotect branch again" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      response.status.should == 200
    end
  end

  describe "POST /projects/:id/repository/branches" do
    it "should create a new branch" do
      post api("/projects/#{project.id}/repository/branches", user),
        branch_name: branch_name,
        ref: branch_sha

      response.status.should == 201

      json_response['name'].should == branch_name
      json_response['commit']['id'].should == branch_sha
    end

    it "should deny for user without push access" do
      post api("/projects/#{project.id}/repository/branches", user2),
        branch_name: branch_name,
        ref: branch_sha

      response.status.should == 403
    end
  end

  describe "DELETE /projects/:id/repository/branches/:branch" do
    before { Repository.any_instance.stub(rm_branch: true) }

    it "should remove branch" do
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      response.status.should == 200
    end

    it "should remove protected branch" do
      project.protected_branches.create(name: branch_name)
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      response.status.should == 405
      json_response['message'].should == 'Protected branch cant be removed'
    end

    it "should not remove HEAD branch" do
      delete api("/projects/#{project.id}/repository/branches/master", user)
      response.status.should == 405
      json_response['message'].should == 'Cannot remove HEAD branch'
    end
  end
end
