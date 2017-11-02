require 'spec_helper'
require 'mime/types'

describe API::V3::Branches do
  set(:user) { create(:user) }
  set(:user2) { create(:user) }
  set(:project) { create(:project, :repository, creator: user) }
  set(:master) { create(:project_member, :master, user: user, project: project) }
  set(:guest) { create(:project_member, :guest, user: user2, project: project) }
  let!(:branch_name) { 'feature' }
  let!(:branch_sha) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }
  let!(:branch_with_dot) { CreateBranchService.new(project, user).execute("with.1.2.3", "master") }

  describe "GET /projects/:id/repository/branches" do
    it "returns an array of project branches" do
      project.repository.expire_all_method_caches

      get v3_api("/projects/#{project.id}/repository/branches", user), per_page: 100

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      branch_names = json_response.map { |x| x['name'] }
      expect(branch_names).to match_array(project.repository.branch_names)
    end
  end

  describe "DELETE /projects/:id/repository/branches/:branch" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it "removes branch" do
      delete v3_api("/projects/#{project.id}/repository/branches/#{branch_name}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['branch_name']).to eq(branch_name)
    end

    it "removes a branch with dots in the branch name" do
      delete v3_api("/projects/#{project.id}/repository/branches/with.1.2.3", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['branch_name']).to eq("with.1.2.3")
    end

    it 'returns 404 if branch not exists' do
      delete v3_api("/projects/#{project.id}/repository/branches/foobar", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "DELETE /projects/:id/repository/merged_branches" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'returns 200' do
      delete v3_api("/projects/#{project.id}/repository/merged_branches", user)

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns a 403 error if guest' do
      delete v3_api("/projects/#{project.id}/repository/merged_branches", user2)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe "POST /projects/:id/repository/branches" do
    it "creates a new branch" do
      post v3_api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'feature1',
           ref: branch_sha

      expect(response).to have_gitlab_http_status(201)

      expect(json_response['name']).to eq('feature1')
      expect(json_response['commit']['id']).to eq(branch_sha)
    end

    it "denies for user without push access" do
      post v3_api("/projects/#{project.id}/repository/branches", user2),
           branch_name: branch_name,
           ref: branch_sha
      expect(response).to have_gitlab_http_status(403)
    end

    it 'returns 400 if branch name is invalid' do
      post v3_api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new design',
           ref: branch_sha
      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Branch name is invalid')
    end

    it 'returns 400 if branch already exists' do
      post v3_api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new_design1',
           ref: branch_sha
      expect(response).to have_gitlab_http_status(201)

      post v3_api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new_design1',
           ref: branch_sha

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Branch already exists')
    end

    it 'returns 400 if ref name is invalid' do
      post v3_api("/projects/#{project.id}/repository/branches", user),
           branch_name: 'new_design3',
           ref: 'foo'

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Invalid reference name')
    end
  end
end
