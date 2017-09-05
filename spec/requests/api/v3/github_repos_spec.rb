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
      get v3_api('/user/repos', user)

      expect(response).to have_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /-/jira/pulls' do
    it 'returns an empty array' do
      get v3_api('/repos/-/jira/pulls', user)

      expect(response).to have_http_status(200)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /users/:id/repos' do
    context 'authenticated' do
      it 'returns an array of projects with github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        group = create(:group)
        create(:project, group: group)
        group.add_master(user)

        get v3_api('/users/foo/repos', user)

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
        get v3_api("/users/foo/repos", nil)

        expect(response).to have_http_status(401)
      end
    end

    it 'filters unlicensed namespace projects' do
      silver_plan = Plan.find_by!(name: 'silver')
      licensed_project = create(:project, :empty_repo)
      licensed_project.add_reporter(user)
      licensed_project.namespace.update!(plan_id: silver_plan.id)

      stub_licensed_features(jira_dev_panel_integration: true)
      stub_application_setting_on_object(project, should_check_namespace_plan: true)
      stub_application_setting_on_object(licensed_project, should_check_namespace_plan: true)

      get v3_api('/users/foo/repos', user)

      expect(response).to have_http_status(200)
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(licensed_project.id)
    end
  end

  describe 'GET /repos/:namespace/:project/branches' do
    context 'authenticated' do
      it 'returns an array of project branches with github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.first.keys).to contain_exactly('name', 'commit')
        expect(json_response.first['commit'].keys).to contain_exactly('sha', 'type')
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", nil)

        expect(response).to have_http_status(401)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when not licensed' do
        stub_licensed_features(jira_dev_panel_integration: false)
        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", unauthorized_user)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/commits/:sha' do
    let(:commit) { project.repository.commit }
    let(:commit_id) { commit.id }

    context 'authenticated' do
      it 'returns commit with github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        commit_author = {
          'name' => commit.author_name,
          'email' => commit.author_email,
          'date' => commit.authored_date.iso8601,
          'type' => 'User'
        }

        commit_committer = {
          'name' => commit.committer_name,
          'email' => commit.committer_email,
          'date' => commit.committed_date.iso8601,
          'type' => 'User'
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

    context 'unauthorized' do
      it 'returns 404 when lower access level' do
        unauthorized_user = create(:user)
        project.add_guest(unauthorized_user)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_http_status(404)
      end

      it 'returns 404 when not licensed' do
        stub_licensed_features(jira_dev_panel_integration: false)
        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_http_status(404)
      end
    end
  end
end
