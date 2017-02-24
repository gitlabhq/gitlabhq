require 'spec_helper'
require 'mime/types'

describe API::V3::Branches, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }

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

  describe "DELETE /projects/:id/repository/merged_branches" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'returns 200' do
      delete v3_api("/projects/#{project.id}/repository/merged_branches", user)

      expect(response).to have_http_status(200)
    end

    it 'returns a 403 error if guest' do
      user_b = create :user
      create(:project_member, :guest, user: user_b, project: project)

      delete v3_api("/projects/#{project.id}/repository/merged_branches", user_b)

      expect(response).to have_http_status(403)
    end
  end
end
