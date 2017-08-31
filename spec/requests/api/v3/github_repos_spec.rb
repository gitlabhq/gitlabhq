require 'spec_helper'

describe API::V3::GithubRepos do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }

  before do
    project.add_master(user)
  end

  describe 'GET /orgs/:id/repos' do
    it 'returns an array of projects' do
      group = create(:group)

      get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_http_status(200)
    end
  end

  describe 'GET /users/:id/repos' do
    it 'returns an array of projects with github format' do
      get v3_api("/users/whatever/repos", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an(Array)
      expect(json_response.size).to eq(1)
      expect(json_response.first.keys).to contain_exactly('id', 'owner', 'name')
      expect(json_response.first['owner'].keys).to contain_exactly('login', 'id')
    end
  end

   describe 'GET /repos/:namespace/:repo/branches' do
     context 'when user namespace path' do
       it 'returns an array of project branches with github format' do
         get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

         expect(response).to have_http_status(200)
         expect(json_response).to be_an(Array)
         expect(json_response.first.keys).to contain_exactly('name', 'commit')
         expect(json_response.first['commit'].keys).to contain_exactly('sha', 'type')
       end
     end

     xcontext 'when group path' do
     end
   end

   describe 'GET /repos/:namespace/:repo/commits/:sha' do
     it 'returns commit with expected format' do
       get v3_api("/repos/#{user.namespace.path}/foo/commits/sha123", user)

       expect(response).to have_http_status(200)
       expect(json_response).to be_a(Hash)
     end
   end
end
