require 'spec_helper'

describe API::V3::GithubRepos do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }

  before do
    project.add_master(user)
  end

  describe 'GET /orgs/:namespace/repos' do
    it 'returns an empty array' do
      group = create(:group)

      get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /user/repos' do
    it 'returns an empty array' do
      get v3_api("/user/repos", user)

      expect(response).to have_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /-/jira/pulls' do
    it 'returns an empty array' do
      get v3_api("/repos/-/jira/pulls", user)

      expect(response).to have_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /users/:id/repos' do
    context 'authenticated' do
      it 'returns an array of projects with github format' do
        group = create(:group)
        create(:project, group: group)

        group.add_master(user)

        get v3_api("/users/whatever/repos", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)

        expect(json_response.first.keys).to contain_exactly('id', 'owner', 'name')
        expect(json_response.first['owner'].keys).to contain_exactly('login')
        expect(json_response.second.keys).to contain_exactly('id', 'owner', 'name')
        expect(json_response.second['owner'].keys).to contain_exactly('login')
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        get v3_api("/users/whatever/repos", nil)

        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /repos/:namespace/:repo/branches' do
    context 'authenticated' do
      context 'when user namespace path' do
        it 'returns an array of project branches with github format' do
          get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

          expect(response).to have_http_status(200)
          expect(json_response).to be_an(Array)
          expect(json_response.first.keys).to contain_exactly('name', 'commit')
          expect(json_response.first['commit'].keys).to contain_exactly('sha', 'type')
        end
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", nil)

        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /repos/:namespace/:repo/commits/:sha' do
    let(:commit) { project.repository.commit }
    let(:commit_id) { commit.id }

    context 'authenticated' do
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
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", nil)

        expect(response).to have_http_status(401)
      end
    end
  end
end
