# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Kubernetes, feature_category: :deployment_management do
  let(:jwt_auth_headers) do
    jwt_token = JWT.encode(
      { 'iss' => Gitlab::Kas::JWT_ISSUER, 'aud' => Gitlab::Kas::JWT_AUDIENCE },
      Gitlab::Kas.secret,
      'HS256'
    )

    { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => jwt_token }
  end

  let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }

  before do
    allow(Gitlab::Kas).to receive(:secret).and_return(jwt_secret)
  end

  shared_examples 'authorization' do
    context 'not authenticated' do
      it 'returns 401' do
        send_request(headers: { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => '' })

        expect(response).to have_gitlab_http_status(:unauthorized)
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
        counters = { k8s_api_proxy_request: 5 }
        unique_counters = { k8s_api_proxy_requests_unique_users_via_ci_access: [10] }

        send_request(params: { counters: counters, unique_counters: unique_counters })

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'uses batched Redis updates' do
        expect(Gitlab::InternalEvents).to receive(:with_batched_redis_writes)

        send_request(params: { counters: { k8s_api_proxy_request: 5 } })
      end

      it 'returns no_content for counts of zero' do
        counters = { k8s_api_proxy_request: 0 }
        unique_counters = { k8s_api_proxy_requests_unique_users_via_ci_access: [] }

        send_request(params: { counters: counters, unique_counters: unique_counters })

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'returns 400 for non counter number' do
        counters = { k8s_api_proxy_request: 'string' }

        send_request(params: { counters: counters })

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 for non unique_counter set' do
        unique_counters = { k8s_api_proxy_requests_unique_users_via_ci_access: 1 }

        send_request(params: { unique_counters: unique_counters })

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      describe 'events tracking' do
        it 'correctly merges legacy Redis keys for migrated metrics', :aggregate_failures do
          legacy_redis_keys = %w[
            USAGE_KUBERNETES_AGENT_FLUX_GIT_PUSH_NOTIFICATIONS_TOTAL
            USAGE_KUBERNETES_AGENT_K8S_API_PROXY_REQUEST
            USAGE_KUBERNETES_AGENT_K8S_API_PROXY_REQUESTS_VIA_CI_ACCESS
            USAGE_KUBERNETES_AGENT_K8S_API_PROXY_REQUESTS_VIA_USER_ACCESS
            USAGE_KUBERNETES_AGENT_K8S_API_PROXY_REQUESTS_VIA_PAT_ACCESS
          ]

          legacy_redis_keys.each do |key|
            Gitlab::Redis::SharedState.with { |redis| redis.set(key, 1) }
          end

          counters = {
            flux_git_push_notifications_total: 1,
            k8s_api_proxy_request: 1,
            k8s_api_proxy_requests_via_ci_access: 1,
            k8s_api_proxy_requests_via_user_access: 1,
            k8s_api_proxy_requests_via_pat_access: 1
          }

          send_request(params: { counters: counters })

          migrated_metrics = %w[
            kubernetes_agent_flux_git_push_notifications_total
            kubernetes_agent_k8s_api_proxy_request
            kubernetes_agent_k8s_api_proxy_requests_via_ci_access
            kubernetes_agent_k8s_api_proxy_requests_via_user_access
            kubernetes_agent_k8s_api_proxy_requests_via_pat_access
          ]

          migrated_metrics.each do |metric|
            metric_definition = Gitlab::Usage::MetricDefinition.definitions["counts.#{metric}"]
            current_value = Gitlab::Usage::Metric.new(metric_definition).send(:instrumentation_object).value
            expect(current_value).to eq(2), "Expected metric #{metric} to be 2, but was #{current_value}"
          end
        end

        it 'tracks counter events', :aggregate_failures do
          events = API::Helpers::Kubernetes::AgentHelpers::COUNTERS_EVENTS_MAPPING
          counters = {
            flux_git_push_notifications_total: 3,
            k8s_api_proxy_request: 5,
            k8s_api_proxy_requests_via_ci_access: 43,
            k8s_api_proxy_requests_via_user_access: 44,
            k8s_api_proxy_requests_via_pat_access: 45
          }

          expect do
            send_request(params: { counters: counters })
          end.to trigger_internal_events(events['flux_git_push_notifications_total'])
                   .with(category: 'InternalEventTracking')
                     .exactly(counters[:flux_git_push_notifications_total]).times
                   .and increment_usage_metrics('counts.kubernetes_agent_flux_git_push_notifications_total')
                    .by(counters[:flux_git_push_notifications_total])
                 .and trigger_internal_events(events['k8s_api_proxy_request'])
                   .with(category: 'InternalEventTracking')
                     .exactly(counters[:k8s_api_proxy_request]).times
                   .and increment_usage_metrics('counts.kubernetes_agent_k8s_api_proxy_request')
                    .by(counters[:k8s_api_proxy_request])
                 .and trigger_internal_events(events['k8s_api_proxy_requests_via_ci_access'])
                   .with(category: 'InternalEventTracking')
                     .exactly(counters[:k8s_api_proxy_requests_via_ci_access]).times
                   .and increment_usage_metrics('counts.kubernetes_agent_k8s_api_proxy_requests_via_ci_access')
                     .by(counters[:k8s_api_proxy_requests_via_ci_access])
                 .and trigger_internal_events(events['k8s_api_proxy_requests_via_user_access'])
                   .with(category: 'InternalEventTracking')
                     .exactly(counters[:k8s_api_proxy_requests_via_user_access]).times
                   .and increment_usage_metrics('counts.kubernetes_agent_k8s_api_proxy_requests_via_user_access')
                     .by(counters[:k8s_api_proxy_requests_via_user_access])
                 .and trigger_internal_events(events['k8s_api_proxy_requests_via_pat_access'])
                   .with(category: 'InternalEventTracking')
                      .exactly(counters[:k8s_api_proxy_requests_via_pat_access]).times
                    .and increment_usage_metrics('counts.kubernetes_agent_k8s_api_proxy_requests_via_pat_access')
                      .by(counters[:k8s_api_proxy_requests_via_pat_access])
        end

        it 'tracks unique events', :aggregate_failures do
          request_count = 2
          users = create_list(:user, 3)
          user_ids = users.map(&:id) << users[0].id

          unique_counters = {
            k8s_api_proxy_requests_unique_agents_via_ci_access: user_ids,
            k8s_api_proxy_requests_unique_agents_via_user_access: user_ids,
            k8s_api_proxy_requests_unique_agents_via_pat_access: user_ids,
            flux_git_push_notified_unique_projects: user_ids,
            k8s_api_proxy_requests_unique_users_via_ci_access: user_ids,
            k8s_api_proxy_requests_unique_users_via_user_access: user_ids,
            k8s_api_proxy_requests_unique_users_via_pat_access: user_ids
          }

          internal_events = %w[
            k8s_api_proxy_requests_unique_users_via_ci_access
            k8s_api_proxy_requests_unique_users_via_user_access
            k8s_api_proxy_requests_unique_users_via_pat_access
          ]

          unique_user_metrics = %w[
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_users_via_ci_access_weekly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_users_via_ci_access_monthly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_users_via_user_access_weekly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_users_via_user_access_monthly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_users_via_pat_access_weekly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_users_via_pat_access_monthly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_agents_via_user_access_weekly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_agents_via_user_access_monthly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_agents_via_ci_access_weekly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_agents_via_ci_access_monthly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_agents_via_pat_access_weekly
            redis_hll_counters.kubernetes_agent.k8s_api_proxy_requests_unique_agents_via_pat_access_monthly
            redis_hll_counters.kubernetes_agent.flux_git_push_notified_unique_projects_weekly
            redis_hll_counters.kubernetes_agent.flux_git_push_notified_unique_projects_monthly
          ]

          expect do
            request_count.times do
              send_request(params: { unique_counters: unique_counters })
            end
          end.to trigger_internal_events(internal_events).with(user: users[0], category: 'InternalEventTracking').exactly(4).times
            .and trigger_internal_events(internal_events).with(user: users[1], category: 'InternalEventTracking').twice
            .and trigger_internal_events(internal_events).with(user: users[2], category: 'InternalEventTracking').twice
            .and increment_usage_metrics(unique_user_metrics).by(user_ids.uniq.count)
        end
      end
    end
  end

  describe 'POST /internal/kubernetes/agent_events', :clean_gitlab_redis_shared_state do
    def send_request(headers: {}, params: {})
      post api('/internal/kubernetes/agent_events'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    include_examples 'authorization'
    include_examples 'error handling'

    context 'is authenticated for an agent' do
      let!(:agent_token) { create(:cluster_agent_token) }

      context 'when events are valid' do
        let(:request_count) { 2 }
        let(:users) { create_list(:user, 3).index_by(&:id) }
        let(:projects) { create_list(:project, 3).index_by(&:id) }
        let(:events) do
          user_ids = users.keys
          project_ids = projects.keys
          event_data = Array.new(3) do |i|
            { user_id: user_ids[i], project_id: project_ids[i] }
          end
          {
            k8s_api_proxy_requests_unique_users_via_ci_access: event_data,
            k8s_api_proxy_requests_unique_users_via_user_access: event_data,
            k8s_api_proxy_requests_unique_users_via_pat_access: event_data,
            register_agent_at_kas: [{
              project_id: projects.each_value.first.id,
              agent_version: "v17.1.0",
              architecture: "arm64"
            },
              {
                project_id: projects.values.last.id,
                agent_version: "v17.0.0",
                architecture: "amd64"
              }]
          }
        end

        it 'tracks events and returns no_content', :aggregate_failures do
          events[:agent_users_using_ci_tunnel] = events.slice(
            :k8s_api_proxy_requests_unique_users_via_ci_access,
            :k8s_api_proxy_requests_unique_users_via_user_access,
            :k8s_api_proxy_requests_unique_users_via_pat_access
          ).values.flatten

          events.each do |event_name, event_list|
            additional_properties = {}
            event_list.each do |event|
              if event_name == :register_agent_at_kas
                additional_properties = {
                  label: event[:agent_version],
                  property: event[:architecture]
                }
              end

              expect(Gitlab::InternalEvents).to receive(:track_event)
                                                  .with(event_name.to_s, additional_properties: additional_properties, user: users[event[:user_id]], project: projects[event[:project_id]])
                                                  .exactly(request_count).times
            end
          end

          request_count.times do
            send_request(params: { events: events })
          end

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when events are empty' do
        let(:events) do
          {
            k8s_api_proxy_requests_unique_users_via_ci_access: [],
            k8s_api_proxy_requests_unique_users_via_user_access: [],
            k8s_api_proxy_requests_unique_users_via_pat_access: [],
            register_agent_at_kas: []
          }
        end

        it 'returns no_content for empty events' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)
          send_request(params: { events: events })

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when events have non-integer values' do
        let(:events) do
          {
            k8s_api_proxy_requests_unique_users_via_ci_access: [
              { user_id: 'string', project_id: 111 }
            ]
          }
        end

        it 'returns 400 for non-integer values' do
          expect(Gitlab::InternalEvents).not_to receive(:track_event)
          send_request(params: { events: events })

          expect(response).to have_gitlab_http_status(:bad_request)
        end
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
              'token' => 'secret'
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
                'token' => 'secret'
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

  describe 'GET /internal/kubernetes/verify_project_access' do
    def send_request(headers: {}, params: {})
      get api("/internal/kubernetes/verify_project_access"), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    include_examples 'authorization'
    include_examples 'agent authentication'
    include_examples 'error handling'

    shared_examples 'access is granted' do
      it 'returns success response' do
        send_request(params: { id: project_id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    shared_examples 'access is denied' do
      it 'returns 404' do
        send_request(params: { id: project_id }, headers: { 'Authorization' => "Bearer #{agent_token.token}" })

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'an agent is found' do
      let_it_be(:agent_token) { create(:cluster_agent_token) }
      let(:project_id) { project.id }

      include_examples 'agent token tracking'

      context 'project is public' do
        let(:project) { create(:project, :public) }

        it_behaves_like 'access is granted'

        context 'repository is for project members only' do
          let(:project) { create(:project, :public, :repository_private) }

          it_behaves_like 'access is denied'
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it_behaves_like 'access is denied'

        context 'and agent belongs to project' do
          let(:agent_token) { create(:cluster_agent_token, agent: create(:cluster_agent, project: project)) }

          it_behaves_like 'access is granted'
        end
      end

      context 'project is internal' do
        let(:project) { create(:project, :internal) }

        it_behaves_like 'access is denied'

        context 'and agent belongs to project' do
          let(:agent_token) { create(:cluster_agent_token, agent: create(:cluster_agent, project: project)) }

          it_behaves_like 'access is granted'
        end
      end

      context 'project does not exist' do
        let(:project_id) { non_existing_record_id }

        it_behaves_like 'access is denied'
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
        session_data: {
          'warden.user.user.key' => [[user.id], user.authenticatable_salt],
          '_csrf_token' => csrf_token
        }
      )
    end

    def stub_user_session_with_no_user_id(user, csrf_token)
      stub_session(
        session_data: {
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

    context 'when the access type is access_token' do
      let(:personal_access_token) { create(:personal_access_token, user: user, scopes: [Gitlab::Auth::K8S_PROXY_SCOPE]) }

      it 'returns 200 when the user has access' do
        deployment_project.add_member(user, :developer)

        send_request(params: { agent_id: agent.id, access_type: 'personal_access_token', access_key: personal_access_token.token })

        expect(response).to have_gitlab_http_status(:success)
      end

      it 'returns 403 when user has no access' do
        send_request(params: { agent_id: agent.id, access_type: 'personal_access_token', access_key: personal_access_token.token })

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 when user has incorrect token scope' do
        personal_access_token.update!(scopes: [Gitlab::Auth::READ_API_SCOPE])
        deployment_project.add_member(user, :developer)

        send_request(params: { agent_id: agent.id, access_type: 'personal_access_token', access_key: personal_access_token.token })

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 when user has no access to requested agent' do
        deployment_project.add_member(user, :developer)

        send_request(params: { agent_id: another_agent.id, access_type: 'personal_access_token', access_key: personal_access_token.token })

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 404 for non-existent agent' do
        send_request(params: { agent_id: non_existing_record_id, access_type: 'personal_access_token', access_key: personal_access_token.token })

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the access type is session_cookie' do
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
end
