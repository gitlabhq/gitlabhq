require 'spec_helper'
require 'mime/types'

describe API::V3::Branches, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:guest) { create(:project_member, :guest, user: user2, project: project) }
  let!(:branch_name) { 'feature' }
  let!(:branch_with_dot) { CreateBranchService.new(project, user).execute("with.1.2.3", "master") }

  describe "GET /projects/:id/repository/branches" do
    it "returns an array of project branches" do
      project.repository.expire_all_method_caches

      get v3_api("/projects/#{project.id}/repository/branches", user), per_page: 100

      expect(response).to have_http_status(200)
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

      expect(response).to have_http_status(200)
      expect(json_response['branch_name']).to eq(branch_name)
    end

    it "removes a branch with dots in the branch name" do
      delete v3_api("/projects/#{project.id}/repository/branches/with.1.2.3", user)

      expect(response).to have_http_status(200)
      expect(json_response['branch_name']).to eq("with.1.2.3")
    end

    it 'returns 404 if branch not exists' do
      delete v3_api("/projects/#{project.id}/repository/branches/foobar", user)
      expect(response).to have_http_status(404)
    end

    it "removes protected branch" do
      create(:protected_branch, project: project, name: branch_name)
      delete v3_api("/projects/#{project.id}/repository/branches/#{branch_name}", user)
      expect(response).to have_http_status(405)
      expect(json_response['message']).to eq('Protected branch cant be removed')
    end

    it "does not remove HEAD branch" do
      delete v3_api("/projects/#{project.id}/repository/branches/master", user)
      expect(response).to have_http_status(405)
      expect(json_response['message']).to eq('Cannot remove HEAD branch')
    end
  end

  describe "DELETE /projects/:id/repository/merged_branches" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'returns 200' do
      delete v3_api("/projects/#{project.id}/repository/merged_branches", user)

      expect(response).to have_http_status(200)
    end

    it 'returns a 403 error if guest' do
      delete v3_api("/projects/#{project.id}/repository/merged_branches", user2)

      expect(response).to have_http_status(403)
    end
  end
end
