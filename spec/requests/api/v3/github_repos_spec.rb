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
    context 'authenticated' do
      it 'returns an array of projects with github format' do
        get v3_api("/users/whatever/repos", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
        expect(json_response.first.keys).to contain_exactly('id', 'owner', 'name')
        expect(json_response.first['owner'].keys).to contain_exactly('login')
      end
    end

    context 'unauthenticated' do
      it 'returns an array of projects with github format' do
        get v3_api("/users/whatever/repos", nil)

        expect(response).to have_http_status(401)
      end
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
     let(:commit) { project.repository.commit }
     let(:commit_id) { commit.id }

     it 'returns commit with expected format' do
       get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

       commit_author = {
         'name' => commit.author_name,
         'email' => commit.author_email,
         'date' => commit.authored_date.iso8601(3)
       }

       commit_committer = {
         'name' => commit.committer_name,
         'email' => commit.committer_email,
         'date' => commit.committed_date.iso8601(3)
       }

       parent_commits = commit.parent_ids.map { |id| { 'sha' => id } }

       expect(response).to have_http_status(200)
       expect(json_response['sha']).to eq(commit.id)
       expect(json_response['parents']).to eq(parent_commits)
       expect(json_response.dig('commit', 'author')).to eq(commit_author)
       expect(json_response.dig('commit', 'committer')).to eq(commit_committer)
       expect(json_response.dig('commit', 'message')).to eq(commit.safe_message)

       # expect(json_response['short_id']).to eq(commit.short_id)
       # expect(json_response['title']).to eq(commit.title)
       # expect(json_response['author_name']).to eq(commit.author_name)
       # expect(json_response['author_email']).to eq(commit.author_email)
       # expect(json_response['authored_date']).to eq(commit.authored_date.iso8601(3))
       # expect(json_response['committer_name']).to eq(commit.committer_name)
       # expect(json_response['committer_email']).to eq(commit.committer_email)
       # expect(json_response['committed_date']).to eq(commit.committed_date.iso8601(3))
       # expect(json_response['parent_ids']).to eq(commit.parent_ids)
       # expect(json_response['stats']['additions']).to eq(commit.stats.additions)
       # expect(json_response['stats']['deletions']).to eq(commit.stats.deletions)
       # expect(json_response['stats']['total']).to eq(commit.stats.total)
       # expect(json_response['status']).to be_nil
     end
   end
end
