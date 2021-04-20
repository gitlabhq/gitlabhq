# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::V3::Github do
  let_it_be(:user) { create(:user) }
  let_it_be(:unauthorized_user) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:project) { create(:project, :repository, creator: user) }

  before do
    project.add_maintainer(user)
  end

  describe 'GET /orgs/:namespace/repos' do
    it 'returns an empty array' do
      group = create(:group)

      jira_get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end

    it 'returns 200 when namespace path include a dot' do
      group = create(:group, path: 'foo.bar')

      jira_get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET /user/repos' do
    it 'returns an empty array' do
      jira_get v3_api('/user/repos', user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end
  end

  shared_examples_for 'Jira-specific mimicked GitHub endpoints' do
    describe 'GET /.../issues/:id/comments' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      let!(:note) do
        create(:note, project: project, noteable: merge_request)
      end

      context 'when user has access to the merge request' do
        it 'returns an array of notes' do
          jira_get v3_api("/repos/#{path}/issues/#{merge_request.id}/comments", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(1)
        end
      end

      context 'when user has no access to the merge request' do
        let(:project) { create(:project, :private) }

        before do
          project.add_guest(user)
        end

        it 'returns 404' do
          jira_get v3_api("/repos/#{path}/issues/#{merge_request.id}/comments", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'GET /.../pulls/:id/commits' do
      it 'returns an empty array' do
        jira_get v3_api("/repos/#{path}/pulls/xpto/commits", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq([])
      end
    end

    describe 'GET /.../pulls/:id/comments' do
      it 'returns an empty array' do
        jira_get v3_api("/repos/#{path}/pulls/xpto/comments", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq([])
      end
    end
  end

  # Here we test that using /-/jira as namespace/project still works,
  # since that is how old Jira setups will talk to us
  context 'old /-/jira endpoints' do
    it_behaves_like 'Jira-specific mimicked GitHub endpoints' do
      let(:path) { '-/jira' }
    end

    it 'returns an empty Array for events' do
      jira_get v3_api('/repos/-/jira/events', user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end
  end

  context 'new :namespace/:project jira endpoints' do
    it_behaves_like 'Jira-specific mimicked GitHub endpoints' do
      let(:path) { "#{project.namespace.path}/#{project.path}" }
    end

    describe 'GET /users/:username' do
      let!(:user1) { create(:user, username: 'jane.porter') }

      context 'user exists' do
        it 'responds with the expected user' do
          jira_get v3_api("/users/#{user.username}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('entities/github/user')
        end
      end

      context 'user does not exist' do
        it 'responds with the expected status' do
          jira_get v3_api('/users/unknown_user_name', user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'no rights to request user lists' do
        before do
          expect(Ability).to receive(:allowed?).with(unauthorized_user, :read_users_list, :global).and_return(false)
          expect(Ability).to receive(:allowed?).at_least(:once).and_call_original
        end

        it 'responds with forbidden' do
          jira_get v3_api("/users/#{user.username}", unauthorized_user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    describe 'GET events' do
      include ProjectForksHelper

      let(:group) { create(:group) }
      let(:project) { create(:project, :empty_repo, path: 'project.with.dot', group: group) }
      let(:events_path) { "/repos/#{group.path}/#{project.path}/events" }

      context 'if there are no merge requests' do
        it 'returns an empty array' do
          jira_get v3_api(events_path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq([])
        end
      end

      context 'if there is a merge request' do
        let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

        it 'returns an event' do
          jira_get v3_api(events_path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(1)
        end
      end

      it 'avoids N+1 queries' do
        create(:merge_request, source_project: project)
        source_project = fork_project(project, nil, repository: true)

        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { jira_get v3_api(events_path, user) }.count

        create_list(:merge_request, 2, :unique_branches, source_project: source_project, target_project: project)

        expect { jira_get v3_api(events_path, user) }.not_to exceed_all_query_limit(control_count)
      end

      context 'if there are more merge requests' do
        let!(:merge_request) { create(:merge_request, id: 10000, source_project: project, target_project: project, author: user) }
        let!(:merge_request2) { create(:merge_request, id: 10001, source_project: project, source_branch: generate(:branch), target_project: project, author: user) }

        it 'returns the expected amount of events' do
          jira_get v3_api(events_path, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(2)
        end

        it 'ensures each event has a unique id' do
          jira_get v3_api(events_path, user)

          ids = json_response.map { |event| event['id'] }.uniq
          expect(ids.size).to eq(2)
        end
      end
    end
  end

  describe 'repo pulls' do
    let_it_be(:project2) { create(:project, :repository, creator: user) }
    let_it_be(:assignee) { create(:user) }
    let_it_be(:assignee2) { create(:user) }
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, author: user, assignees: [assignee])
    end

    let_it_be(:merge_request_2) do
      create(:merge_request, source_project: project2, target_project: project2, author: user, assignees: [assignee, assignee2])
    end

    before do
      project2.add_maintainer(user)
    end

    def perform_request
      jira_get v3_api(route, user)
    end

    describe 'GET /-/jira/pulls' do
      let(:route) { '/repos/-/jira/pulls' }

      it 'returns an array of merge requests with github format' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)
        expect(response).to match_response_schema('entities/github/pull_requests')
      end

      it 'returns multiple merge requests without N + 1' do
        perform_request

        control_count = ActiveRecord::QueryRecorder.new { perform_request }.count

        project3 = create(:project, :repository, creator: user)
        project3.add_maintainer(user)
        assignee3 = create(:user)
        create(:merge_request, source_project: project3, target_project: project3, author: user, assignees: [assignee3])

        expect { perform_request }.not_to exceed_query_limit(control_count)
      end
    end

    describe 'GET /repos/:namespace/:project/pulls' do
      let(:route) { "/repos/#{project.namespace.path}/#{project.path}/pulls" }

      it 'returns an array of merge requests for the proper project in github format' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
        expect(response).to match_response_schema('entities/github/pull_requests')
      end

      it 'returns multiple merge requests without N + 1' do
        perform_request

        control_count = ActiveRecord::QueryRecorder.new { perform_request }.count

        create(:merge_request, source_project: project, source_branch: 'fix')

        expect { perform_request }.not_to exceed_query_limit(control_count)
      end
    end

    describe 'GET /repos/:namespace/:project/pulls/:id' do
      context 'when user has access to the merge requests' do
        it 'returns the requested merge request in github format' do
          jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/pulls/#{merge_request.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('entities/github/pull_request')
        end
      end

      context 'when user has no access to the merge request' do
        it 'returns 404' do
          project.add_guest(unauthorized_user)

          jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/pulls/#{merge_request.id}", unauthorized_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when instance admin' do
        it 'returns the requested merge request in github format' do
          jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/pulls/#{merge_request.id}", admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('entities/github/pull_request')
        end
      end
    end
  end

  describe 'GET /users/:namespace/repos' do
    let(:group) { create(:group, name: 'foo') }

    def expect_project_under_namespace(projects, namespace, user)
      jira_get v3_api("/users/#{namespace.path}/repos", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('entities/github/repositories')

      projects.each do |project|
        hash = json_response.find do |hash|
          hash['name'] == ::Gitlab::Jira::Dvcs.encode_project_name(project)
        end

        raise "Project #{project.full_path} not present in response" if hash.nil?

        expect(hash['owner']['login']).to eq(namespace.path)
      end
      expect(json_response.size).to eq(projects.size)
    end

    context 'group namespace' do
      let(:project) { create(:project, group: group) }
      let!(:project2) { create(:project, :public, group: group) }

      it 'returns an array of projects belonging to group excluding the ones user is not directly a member of, even when public' do
        expect_project_under_namespace([project], group, user)
      end

      context 'when instance admin' do
        let(:user) { create(:user, :admin) }

        it 'returns an array of projects belonging to group' do
          expect_project_under_namespace([project, project2], group, user)
        end

        context 'with a private group' do
          let(:group) { create(:group, :private) }
          let!(:project2) { create(:project, :private, group: group) }

          it 'returns an array of projects belonging to group' do
            expect_project_under_namespace([project, project2], group, user)
          end
        end
      end
    end

    context 'nested group namespace' do
      let(:group) { create(:group, :nested) }
      let!(:parent_group_project) { create(:project, group: group.parent, name: 'parent_group_project') }
      let!(:child_group_project) { create(:project, group: group, name: 'child_group_project') }

      before do
        group.parent.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([parent_group_project, child_group_project], group.parent, user)
      end

      it 'avoids N+1 queries' do
        jira_get v3_api("/users/#{group.parent.path}/repos", user)

        control = ActiveRecord::QueryRecorder.new { jira_get v3_api("/users/#{group.parent.path}/repos", user) }

        new_group = create(:group, parent: group.parent)
        create(:project, :repository, group: new_group, creator: user)

        expect { jira_get v3_api("/users/#{group.parent.path}/repos", user) }.not_to exceed_query_limit(control)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'user namespace' do
      let(:project) { create(:project, namespace: user.namespace) }

      it 'returns an array of projects belonging to user namespace with github format' do
        expect_project_under_namespace([project], user.namespace, user)
      end
    end

    context 'namespace path includes a dot' do
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group, name: 'foo.bar') }

      before do
        group.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([project], group, user)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        jira_get v3_api('/users/foo/repos', nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'namespace does not exist' do
      it 'responds with not found status' do
        jira_get v3_api('/users/noo/repos', user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/branches' do
    context 'authenticated' do
      context 'updating project feature usage' do
        it 'counts Jira Cloud integration as enabled' do
          user_agent = 'Jira DVCS Connector Vertigo/4.42.0'

          freeze_time do
            jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user), user_agent

            expect(project.reload.jira_dvcs_cloud_last_sync_at).to be_like_time(Time.now)
          end
        end

        it 'counts Jira Server integration as enabled' do
          user_agent = 'Jira DVCS Connector/3.2.4'

          freeze_time do
            jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user), user_agent

            expect(project.reload.jira_dvcs_server_last_sync_at).to be_like_time(Time.now)
          end
        end
      end

      it 'returns an array of project branches with github format' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)

        expect(response).to match_response_schema('entities/github/branches')
      end

      it 'returns 200 when project path include a dot' do
        project.update!(path: 'foo.bar')

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns 200 when namespace path include a dot' do
        group = create(:group, path: 'foo.bar')
        project = create(:project, :repository, group: group)
        project.add_reporter(user)

        jira_get v3_api("/repos/#{group.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when lower access level' do
        project.add_guest(unauthorized_user)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/commits/:sha' do
    let(:commit) { project.repository.commit }
    let(:commit_id) { commit.id }

    context 'authenticated' do
      it 'returns commit with github format' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('entities/github/commit')
      end

      it 'returns 200 when project path include a dot' do
        project.update!(path: 'foo.bar')

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns 200 when namespace path include a dot' do
        group = create(:group, path: 'foo.bar')
        project = create(:project, :repository, group: group)
        project.add_reporter(user)

        jira_get v3_api("/repos/#{group.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when lower access level' do
        project.add_guest(unauthorized_user)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def jira_get(path, user_agent = 'Jira DVCS Connector/3.2.4')
    get path, headers: { 'User-Agent' => user_agent }
  end

  def v3_api(path, user = nil, personal_access_token: nil, oauth_access_token: nil)
    api(
      path,
      user,
      version: 'v3',
      personal_access_token: personal_access_token,
      oauth_access_token: oauth_access_token
    )
  end
end
