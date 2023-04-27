# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Kubernetes, feature_category: :deployment_management do
  let(:jwt_auth_headers) do
    jwt_token = JWT.encode({ 'iss' => Gitlab::Kas::JWT_ISSUER }, Gitlab::Kas.secret, 'HS256')

    { Gitlab::Kas::INTERNAL_API_REQUEST_HEADER => jwt_token }
  end

  let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }

  before do
    allow(Gitlab::Kas).to receive(:secret).and_return(jwt_secret)
  end

  shared_examples 'authorization' do
    context 'not authenticated' do
      it 'returns 401' do
        send_request(headers: { Gitlab::Kas::INTERNAL_API_REQUEST_HEADER => '' })

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'kubernetes_agent_internal_api feature flag disabled' do
      before do
        stub_feature_flags(kubernetes_agent_internal_api: false)
      end

      it 'returns 404' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'agent authentication' do
    it 'returns 401 if Authorization header not sent' do
      send_request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 401 if Authorization is for non-existent agent' do
      send_request(headers: { 'Authorization' => 'Bearer NONEXISTENT' })

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'agent token tracking' do
    it 'tracks token usage' do
      expect do
        send_request(headers: { 'Authorization' => "Bearer #{agent_token.token}" })
      end.to change { agent_token.reload.read_attribute(:last_used_at) }
    end
  end

  shared_examples 'error handling' do
    let!(:agent_token) { create(:cluster_agent_token) }

    # this test verifies fix for an issue where AgentToken passed in Authorization
    # header broke error handling in the api_helpers.rb. It can be removed after
    # https://gitlab.com/gitlab-org/gitlab/-/issues/406582 is done
    it 'returns correct error for the endpoint' do
      allow(Gitlab::Kas).to receive(:verify_api_request).and_raise(StandardError.new('Unexpected Error'))

      send_request(headers: { 'Authorization' => "Bearer #{agent_token.token}" })

      expect(response).to have_gitlab_http_status(:internal_server_error)
      expect(response.body).to include("Unexpected Error")
    end
  end

  describe 'POST /internal/kubernetes/usage_metrics', :clean_gitlab_redis_shared_state do
    def send_request(headers: {}, params: {})
      post api('/internal/kubernetes/usage_metrics'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    include_examples 'authorization'
    include_examples 'error handling'

    context 'is authenticated for an agent' do
      let!(:agent_token) { create(:cluster_agent_token) }

      it 'returns no_content for valid events' do
        counters = { gitops_sync: 10, k8s_api_proxy_request: 5 }
        unique_counters = { agent_users_using_ci_tunnel: [10] }

        send_request(params: { counters: counters, unique_counters: unique_counters })

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'returns no_content for counts of zero' do
        counters = { gitops_sync: 0, k8s_api_proxy_request: 0 }
        unique_counters = { agent_users_using_ci_tunnel: [] }

        send_request(params: { counters: counters, unique_counters: unique_counters })

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'returns 400 for non counter number' do
        counters = { gitops_sync: 'string', k8s_api_proxy_request: 0 }

        send_request(params: { counters: counters })

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 for non unique_counter set' do
        unique_counters = { agent_users_using_ci_tunnel: 1 }

        send_request(params: { unique_counters: unique_counters })

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'tracks events and unique events', :aggregate_failures do
        request_count = 2
        counters = { gitops_sync: 10, k8s_api_proxy_request: 5 }
        unique_counters = { agent_users_using_ci_tunnel: [10, 999, 777, 10] }
        expected_counters = {
          kubernetes_agent_gitops_sync: request_count * counters[:gitops_sync],
          kubernetes_agent_k8s_api_proxy_request: request_count * counters[:k8s_api_proxy_request]
        }
        expected_hll_count = unique_counters[:agent_users_using_ci_tunnel].uniq.count

        request_count.times do
          send_request(params: { counters: counters, unique_counters: unique_counters })
        end

        expect(Gitlab::UsageDataCounters::KubernetesAgentCounter.totals).to eq(expected_counters)

        expect(
          Gitlab::UsageDataCounters::HLLRedisCounter
            .unique_events(
              event_names: 'agent_users_using_ci_tunnel',
              start_date: Date.current, end_date: Date.current + 10
            )
        ).to eq(expected_hll_count)
      end
    end
  end

  describe 'POST /internal/kubernetes/agent_configuration' do
    def send_request(headers: {}, params: {})
      post api('/internal/kubernetes/agent_configuration'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:agent) { create(:cluster_agent, project: project) }
    let_it_be(:config) do
      {
        ci_access: {
          groups: [
            { id: group.full_path, default_namespace: 'production' }
          ],
          projects: [
            { id: project.full_path, default_namespace: 'staging' }
          ]
        },
        user_access: {
          groups: [
            { id: group.full_path }
          ],
          projects: [
            { id: project.full_path }
          ]
        }
      }
    end

    include_examples 'authorization'
    include_examples 'error handling'

    context 'agent exists' do
      it 'configures the agent and returns a 204' do
        send_request(params: { agent_id: agent.id, agent_config: config })

        expect(response).to have_gitlab_http_status(:no_content)
        expect(agent.ci_access_authorized_groups).to contain_exactly(group)
        expect(agent.ci_access_authorized_projects).to contain_exactly(project)
        expect(agent.user_access_authorized_groups).to contain_exactly(group)
        expect(agent.user_access_authorized_projects).to contain_exactly(project)
      end
    end

    context 'agent does not exist' do
      it 'returns a 404' do
        send_request(params: { agent_id: -1, agent_config: config })

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /internal/kubernetes/agent_info' do
    def send_request(headers: {}, params: {})
      get api('/internal/kubernetes/agent_info'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    include_examples 'authorization'
    include_examples 'agent authentication'
    include_examples 'error handling'

    context 'an agent is found' do
      let!(:agent_token) { create(:cluster_agent_token) }

      let(:agent) { agent_token.agent }
      let(:project) { agent.project }

      include_examples 'agent token tracking'

      it 'returns expected data', :aggregate_failures do
        send_request(headers: { 'Authorization' => "Bearer #{agent_token.token}" })

        expect(response).to have_gitlab_http_status(:success)

        expect(json_response).to match(
          a_hash_including(
            'project_id' => project.id,
            'agent_id' => agent.id,
            'agent_name' => agent.name,
            'gitaly_info' => a_hash_including(
              'address' => match(/\.socket$/),
              'token' => 'secret',
              'features' => {}
            ),
            'gitaly_repository' => a_hash_including(
              'storage_name' => project.repository_storage,
              'relative_path' => project.disk_path + '.git',
              'gl_repository' => "project-#{project.id}",
              'gl_project_path' => project.full_path
            ),
            'default_branch' => project.default_branch_or_main
          )
        )
      end
    end
  end

  describe 'GET /internal/kubernetes/project_info' do
    def send_request(headers: {}, params: {})
      get api('/internal/kubernetes/project_info'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    include_examples 'authorization'
    include_examples 'agent authentication'
    include_examples 'error handling'

    context 'an agent is found' do
      let_it_be(:agent_token) { create(:cluster_agent_token) }

      include_examples 'agent token tracking'

      context 'project is public' do
        let(:project) { create(:project, :public) }

        it 'returns expected data', :aggregate_failures do
          send_request(params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

          expect(response).to have_gitlab_http_status(:success)

          expect(json_response).to match(
            a_hash_including(
              'project_id' => project.id,
              'gitaly_info' => a_hash_including(
                'address' => match(/\.socket$/),
                'token' => 'secret',
                'features' => {}
              ),
              'gitaly_repository' => a_hash_including(
                'storage_name' => project.repository_storage,
                'relative_path' => project.disk_path + '.git',
                'gl_repository' => "project-#{project.id}",
                'gl_project_path' => project.full_path
              ),
              'default_branch' => project.default_branch_or_main
            )
          )
        end

        context 'repository is for project members only' do
          let(:project) { create(:project, :public, :repository_private) }

          it 'returns 404' do
            send_request(params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404' do
          send_request(params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'and agent belongs to project' do
          let(:agent_token) { create(:cluster_agent_token, agent: create(:cluster_agent, project: project)) }

          it 'returns 200' do
            send_request(params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

            expect(response).to have_gitlab_http_status(:success)
          end
        end
      end

      context 'project is internal' do
        let(:project) { create(:project, :internal) }

        it 'returns 404' do
          send_request(params: { id: project.id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'project does not exist' do
        it 'returns 404' do
          send_request(params: { id: non_existing_record_id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST /internal/kubernetes/authorize_proxy_user', :clean_gitlab_redis_sessions do
    include SessionHelpers

    def send_request(headers: {}, params: {})
      post api('/internal/kubernetes/authorize_proxy_user'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    def stub_user_session(user, csrf_token)
      stub_session(
        {
          'warden.user.user.key' => [[user.id], user.authenticatable_salt],
          '_csrf_token' => csrf_token
        }
      )
    end

    def stub_user_session_with_no_user_id(user, csrf_token)
      stub_session(
        {
          'warden.user.user.key' => [[nil], user.authenticatable_salt],
          '_csrf_token' => csrf_token
        }
      )
    end

    def mask_token(encoded_token)
      controller = ActionController::Base.new
      raw_token = controller.send(:decode_csrf_token, encoded_token)
      controller.send(:mask_token, raw_token)
    end

    def new_token
      ActionController::Base.new.send(:generate_csrf_token)
    end

    let_it_be(:organization) { create(:group) }
    let_it_be(:configuration_project) { create(:project, group: organization) }
    let_it_be(:agent) { create(:cluster_agent, name: 'the-agent', project: configuration_project) }
    let_it_be(:another_agent) { create(:cluster_agent) }
    let_it_be(:deployment_project) { create(:project, group: organization) }
    let_it_be(:deployment_group) { create(:group, parent: organization) }

    let(:user_access_config) do
      {
        'user_access' => {
          'access_as' => { 'agent' => {} },
          'projects' => [{ 'id' => deployment_project.full_path }],
          'groups' => [{ 'id' => deployment_group.full_path }]
        }
      }
    end

    let(:user) { create(:user) }

    before do
      allow(::Gitlab::Kas).to receive(:enabled?).and_return true
      Clusters::Agents::Authorizations::UserAccess::RefreshService.new(agent, config: user_access_config).execute
    end

    it 'returns 400 when cookie is invalid' do
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: '123', csrf_token: mask_token(new_token) })

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 401 when session is not found' do
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id('abc')
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(new_token) })

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 401 when CSRF token does not match' do
      public_id = stub_user_session(user, new_token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(new_token) })

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 404 for non-existent agent' do
      token = new_token
      public_id = stub_user_session(user, token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: non_existing_record_id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(token) })

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 403 when user has no access' do
      token = new_token
      public_id = stub_user_session(user, token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(token) })

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 200 when user has access' do
      deployment_project.add_member(user, :developer)
      token = new_token
      public_id = stub_user_session(user, token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(token) })

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'returns 401 when user has valid KAS cookie and CSRF token but has no access to requested agent' do
      deployment_project.add_member(user, :developer)
      token = new_token
      public_id = stub_user_session(user, token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: another_agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(token) })

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 401 when global flag is disabled' do
      stub_feature_flags(kas_user_access: false)

      deployment_project.add_member(user, :developer)
      token = new_token
      public_id = stub_user_session(user, token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(token) })

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 401 when user id is not found in session' do
      deployment_project.add_member(user, :developer)
      token = new_token
      public_id = stub_user_session_with_no_user_id(user, token)
      access_key = Gitlab::Kas::UserAccess.encrypt_public_session_id(public_id)
      send_request(params: { agent_id: agent.id, access_type: 'session_cookie', access_key: access_key, csrf_token: mask_token(token) })

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
