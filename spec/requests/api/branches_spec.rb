require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:guest) { create(:project_member, user: user2, project: project, access_level: ProjectMember::GUEST) }
  let!(:branch_name) { 'feature' }
  let!(:branch_sha) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

  describe "GET /projects/:id/repository/branches" do
    it "should return an array of project branches" do
      project.repository.expire_cache

      get api("/projects/#{project.id}/repository/branches", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      branch_names = json_response.map { |x| x['name'] }
      expect(branch_names).to match_array(project.repository.branch_names)
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    it "should return the branch information for a single branch" do
      get api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      expect(response.status).to eq(200)

      expect(json_response['name']).to eq(branch_name)
      expect(json_response['commit']['id']).to eq(branch_sha)
      expect(json_response['protected']).to eq(false)
    end

    it "should return a 403 error if guest" do
      get api("/projects/#{project.id}/repository/branches", user2)
      expect(response.status).to eq(403)
    end

    it "should return a 404 error if branch is not available" do
      get api("/projects/#{project.id}/repository/branches/unknown", user)
      expect(response.status).to eq(404)
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/protect" do
    it "should protect a single branch" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
      expect(response.status).to eq(200)

      expect(json_response['name']).to eq(branch_name)
      expect(json_response['commit']['id']).to eq(branch_sha)
      expect(json_response['protected']).to eq(true)
    end

    it "should return a 404 error if branch not found" do
      put api("/projects/#{project.id}/repository/branches/unknown/protect", user)
      expect(response.status).to eq(404)
    end

    it "should return a 403 error if guest" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user2)
      expect(response.status).to eq(403)
    end

    it "should return success when protect branch again" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
      expect(response.status).to eq(200)
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/unprotect" do
    it "should unprotect a single branch" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      expect(response.status).to eq(200)

      expect(json_response['name']).to eq(branch_name)
      expect(json_response['commit']['id']).to eq(branch_sha)
      expect(json_response['protected']).to eq(false)
    end

    it "should return success when unprotect branch" do
      put api("/projects/#{project.id}/repository/branches/unknown/unprotect", user)
      expect(response.status).to eq(404)
    end

    it "should return success when unprotect branch again" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      expect(response.status).to eq(200)
    end
  end

  describe "POST /projects/:id/repository/branches" do
    it "should create a new branch" do
      post api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'feature1',
           ref: branch_sha

      expect(response.status).to eq(201)

      expect(json_response['name']).to eq('feature1')
      expect(json_response['commit']['id']).to eq(branch_sha)
    end

    it "should deny for user without push access" do
      post api("/projects/#{project.id}/repository/branches", user2),
           branch_name: branch_name,
           ref: branch_sha
      expect(response.status).to eq(403)
    end

    it 'should return 400 if branch name is invalid' do
      post api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new design',
           ref: branch_sha
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq('Branch name invalid')
    end

    it 'should return 400 if branch already exists' do
      post api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new_design1',
           ref: branch_sha
      expect(response.status).to eq(201)

      post api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new_design1',
           ref: branch_sha
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq('Branch already exists')
    end

    it 'should return 400 if ref name is invalid' do
      post api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new_design3',
           ref: 'foo'
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq('Invalid reference name')
    end
  end

  describe "DELETE /projects/:id/repository/branches/:branch" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it "should remove branch" do
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      expect(response.status).to eq(200)
      expect(json_response['branch_name']).to eq(branch_name)
    end

    it 'should return 404 if branch not exists' do
      delete api("/projects/#{project.id}/repository/branches/foobar", user)
      expect(response.status).to eq(404)
    end

    it "should remove protected branch" do
      project.protected_branches.create(name: branch_name)
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      expect(response.status).to eq(405)
      expect(json_response['message']).to eq('Protected branch cant be removed')
    end

    it "should not remove HEAD branch" do
      delete api("/projects/#{project.id}/repository/branches/master", user)
      expect(response.status).to eq(405)
      expect(json_response['message']).to eq('Cannot remove HEAD branch')
    end
  end
end
