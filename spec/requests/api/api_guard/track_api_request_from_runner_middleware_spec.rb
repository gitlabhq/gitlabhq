# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::APIGuard::TrackAPIRequestFromRunnerMiddleware, :request_store, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  RSpec.shared_examples 'event tracking' do
    let(:all_metrics) do
      [
        "redis_hll_counters.count_#{property}s_from_api_request_from_runner_weekly",
        "redis_hll_counters.count_#{property}s_from_api_request_from_runner_monthly"
      ]
    end

    it 'logs to Snowplow, Redis, and product analytics tooling',
      :clean_gitlab_redis_shared_state, :aggregate_failures do
      expected_attributes = {
        project: project,
        namespace: project.namespace,
        category: 'InternalEventTracking',
        feature_enabled_by_namespace_ids: nil,
        additional_properties: {
          **additional_properties,
          **{
            label: label,
            property: property
          }.compact
        }
      }

      expect { subject }
        .to trigger_internal_events(event)
        .with(expected_attributes)
        .and increment_usage_metrics(*all_metrics)
    end
  end

  RSpec.shared_examples 'event not tracked' do
    it 'does not record an internal event' do
      expect(Gitlab::InternalEvents).not_to receive(:track_event).with(event, any_args)

      subject
    end
  end

  it 'is loaded' do
    expect(API::API.middleware).to include([:use, described_class])
  end

  describe '#after' do
    context 'when requesting an endpoint from a runner' do
      let_it_be(:token_user) { create(:user) }
      let_it_be(:token_user_project) { create(:project, developers: token_user) }
      let_it_be(:status) { 200 }

      let_it_be(:personal_access_token) { create(:personal_access_token, user: token_user).token }
      let_it_be(:deploy_token) { create(:deploy_token).token }
      let_it_be(:ci_job_token) { create(:ci_build, :running, user: token_user, project: token_user_project).token }

      let_it_be(:token) { personal_access_token }
      let_it_be(:token_param) { :private_token }
      let_it_be(:endpoint) { '/test' }
      let_it_be(:ip_address) { '10.0.0.1' }
      let!(:runner_machine) { create(:ci_runner_machine, ip_address: ip_address) }

      let_it_be(:event) { 'api_request_from_runner' }
      let_it_be(:project) { token_user_project }
      let_it_be(:label) { "GET /api/:version#{endpoint}" }
      let_it_be(:property) { 'personal_access_token' }
      let_it_be(:additional_properties) { { cross_project_request: '' } }

      let_it_be(:app) do
        Class.new(API::API).tap do |app|
          app.route_setting :authentication, job_token_allowed: true
          app.get endpoint do
            user_project
            status params[:status].to_i
          end
        end
      end

      subject(:request) do
        get api(endpoint),
          params: { id: token_user_project&.id, token_param => token, status: status },
          headers: { REMOTE_ADDR: ip_address }
      end

      it_behaves_like 'event tracking'

      context 'when the endpoint return status is not in the 200 range' do
        let(:status) { 500 }

        it_behaves_like 'event not tracked'
      end

      context 'when there is no project available' do
        let(:token_user_project) { nil }

        it_behaves_like 'event not tracked'
      end

      context 'when there is no token available' do
        let(:token) { nil }

        it_behaves_like 'event not tracked'
      end

      context 'when the `track_api_request_from_runner` feature flag is disabled' do
        before do
          stub_feature_flags(track_api_request_from_runner: false)
        end

        it_behaves_like 'event not tracked'
      end

      context 'when no runner machines exist with the remote ip address' do
        let(:runner_machine) { nil }

        it_behaves_like 'event not tracked'
      end

      context 'with different token types' do
        let_it_be(:project_bot) { create(:user, :project_bot) }
        let_it_be(:project_bot_project) { create(:project, developers: project_bot) }
        let_it_be(:project_access_token) { create(:personal_access_token, user: project_bot).token }
        let_it_be(:group_bot) { create(:user, :project_bot) }
        let_it_be(:group_bot_group) { create(:group, developers: group_bot) }
        let_it_be(:group_access_token) { create(:personal_access_token, user: group_bot).token }
        let_it_be(:oauth_application_secret) do
          create(:oauth_access_token, scopes: [:api]).tap do |oauth_access_token|
            oauth_access_token.update_column(:token, oauth_access_token.application.secret)
          end.application.plaintext_secret
        end

        let_it_be(:app) do
          Class.new(API::API).tap do |app|
            app.route_setting :authentication, deploy_token_allowed: true
            app.get endpoint do
              @project = Project.find(params[:id])
              status find_user_from_sources ? 200 : 401
            end
          end
        end

        where(:token, :token_param, :token_header, :token_type) do
          ref(:personal_access_token)    | :private_token | nil                 | 'personal_access_token'
          ref(:project_access_token)     | :private_token | nil                 | 'project_access_token'
          ref(:group_access_token)       | :private_token | nil                 | 'group_access_token'
          ref(:deploy_token)             | nil            | 'HTTP_DEPLOY_TOKEN' | 'deploy_token'
          ref(:oauth_application_secret) | :access_token  | nil                 | 'oauth_application_secret'
        end

        with_them do
          subject(:request) do
            get api(endpoint),
              params: { id: token_user_project.id, token_param => token },
              headers: { REMOTE_ADDR: ip_address, token_header => token }
          end

          it_behaves_like 'event tracking' do
            let(:property) { token_type }
          end
        end

        context 'with cluster agent token' do
          let_it_be(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil).token }
          let_it_be(:app) do
            Class.new(API::API).tap do |app|
              app.helpers ::API::Helpers::Kubernetes::AgentHelpers
              app.route_setting :authentication, cluster_agent_token_allowed: true
              app.get endpoint do
                @project = Project.find(params[:id])
                status agent_token ? 200 : 401
              end
            end
          end

          subject(:request) do
            get api(endpoint),
              params: { id: token_user_project.id },
              headers: { REMOTE_ADDR: ip_address, 'Gitlab-Agentk-Api-Request' => cluster_agent_token }
          end

          it_behaves_like 'event tracking' do
            let(:property) { 'cluster_agent_token' }
          end
        end
      end

      context 'with token from namespace inheritable' do
        let_it_be(:app) do
          Class.new(API::API).tap do |app|
            app.include ::API::Helpers::Authentication

            app.authenticate_with do |accept|
              accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
              accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
              accept.token_types(:job_token).sent_through(:http_job_token_header)
            end

            app.get endpoint do
              @project = Project.find(params[:id])
              status find_user_from_sources ? 200 : 401
            end
          end
        end

        where(:token, :token_header, :token_type) do
          ref(:personal_access_token) | 'Private-Token' | 'personal_access_token'
          ref(:deploy_token)          | 'Deploy-Token'  | 'deploy_token'
          ref(:ci_job_token)          | 'Job-Token'     | 'ci_job_token'
        end

        with_them do
          subject(:request) do
            get api(endpoint),
              params: { id: token_user_project.id },
              headers: { REMOTE_ADDR: ip_address, token_header => token }
          end

          it_behaves_like 'event tracking' do
            let(:additional_properties) { { cross_project_request: token_type == 'ci_job_token' ? 'false' : '' } }
            let(:property) { token_type }
          end
        end
      end

      context 'when the request is authenticated with a job token' do
        let(:property) { 'ci_job_token' }
        let(:token_param) { :job_token }

        context 'when a resource from the same project is requested' do
          let(:token) { ci_job_token }

          it_behaves_like 'event tracking' do
            let(:additional_properties) { { cross_project_request: 'false' } }
          end
        end

        context 'when a resource from another project is requested' do
          let(:build) { create(:ci_build, :running, user: token_user) }
          let(:token) { build.token }

          before do
            create(:ci_job_token_project_scope_link,
              source_project: token_user_project,
              target_project: build.project,
              direction: :inbound
            )
          end

          it_behaves_like 'event tracking' do
            let(:additional_properties) { { cross_project_request: 'true' } }
          end
        end
      end
    end
  end
end
