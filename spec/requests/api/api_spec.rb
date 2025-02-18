# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::API, feature_category: :system_access do
  include GroupAPIHelpers
  include Auth::DpopTokenHelper

  describe 'Record user last activity in after hook' do
    # It does not matter which endpoint is used because last_activity_on should
    # be updated on every request. `/groups` is used as an example
    # to represent any API endpoint
    let(:user) { create(:user, last_activity_on: Date.yesterday) }

    it 'updates the users last_activity_on to the current date' do
      expect(Users::ActivityService).to receive(:new).with(author: user, project: nil, namespace: nil).and_call_original

      expect { get api('/groups', user) }.to change { user.reload.last_activity_on }.to(Date.today)
    end

    context "with a project-specific path" do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:user) { project.first_owner }

      it "passes correct arguments to ActivityService" do
        activity_args = { author: user, project: project, namespace: project.group }
        expect(Users::ActivityService).to receive(:new).with(activity_args).and_call_original

        get(api("/projects/#{project.id}/issues", user))
      end
    end
  end

  describe 'DPoP authentication' do
    context 'when :dpop_authentication FF is disabled' do
      let(:user) { create(:user) }

      it 'does not check for DPoP token' do
        stub_feature_flags(dpop_authentication: false)

        get api('/groups')
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when :dpop_authentication FF is enabled' do
      before do
        stub_feature_flags(dpop_authentication: true)
      end

      context 'when DPoP is disabled for the user' do
        let(:user) { create(:user) }

        it 'does not check for DPoP token' do
          get api('/groups')
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when DPoP is enabled for the user' do
        let_it_be(:user) { create(:user, dpop_enabled: true) }
        let_it_be(:personal_access_token) { create(:personal_access_token, user: user, scopes: [:api]) }
        let_it_be(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:api]) }
        let_it_be(:dpop_proof) { generate_dpop_proof_for(user) }

        context 'when API is called with an OAuth token' do
          it 'does not invoke DPoP' do
            get api('/groups', oauth_access_token: oauth_token)
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'with a missing DPoP token' do
          it 'returns 401' do
            get api('/groups', personal_access_token: personal_access_token)
            expect(json_response["error_description"]).to eq("DPoP validation error: DPoP header is missing")
            expect(response).to have_gitlab_http_status(:unauthorized)
          end
        end

        context 'with a valid DPoP token' do
          it 'returns 200' do
            get(api('/groups', personal_access_token: personal_access_token), headers: { "dpop" => dpop_proof.proof })
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'with a malformed DPoP token' do
          it 'returns 401' do
            get(api('/groups', personal_access_token: personal_access_token), headers: { "dpop" => 'invalid' })
            # rubocop:disable Layout/LineLength -- We need the entire error message
            expect(json_response["error_description"]).to eq("DPoP validation error: Malformed JWT, unable to decode. Not enough or too many segments")
            # rubocop:enable Layout/LineLength
            expect(response).to have_gitlab_http_status(:unauthorized)
          end
        end
      end
    end
  end

  describe 'User with only read_api scope personal access token' do
    # It does not matter which endpoint is used because this should behave
    # in the same way for every request. `/groups` is used as an example
    # to represent any API endpoint

    context 'when personal access token has only read_api scope' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:token) { create(:personal_access_token, user: user, scopes: [:read_api]) }

      before_all do
        group.add_owner(user)
      end

      it 'does authorize user for get request' do
        get api('/groups', personal_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does authorize user for head request' do
        head api('/groups', personal_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not authorize user for revoked token' do
        revoked = create(:personal_access_token, :revoked, user: user, scopes: [:read_api])

        get api('/groups', personal_access_token: revoked)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'does not authorize user for post request' do
        params = attributes_for_group_api

        post api("/groups", personal_access_token: token), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'logs auth failure fields for post request' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys).to include(
            'correlation_id' => an_instance_of(String),
            'meta.auth_fail_reason' => "insufficient_scope",
            'meta.auth_fail_token_id' => "PersonalAccessToken/#{token.id}",
            'meta.auth_fail_requested_scopes' => "api read_api",
            'route' => '/api/:version/groups'
          )
        end

        params = attributes_for_group_api

        post api("/groups", personal_access_token: token), params: params
      end

      it 'does not authorize user for put request' do
        group_param = { name: 'Test' }

        put api("/groups/#{group.id}", personal_access_token: token), params: group_param

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not authorize user for delete request' do
        delete api("/groups/#{group.id}", personal_access_token: token)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'authentication with deploy token' do
    context 'admin mode' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:package) { create(:maven_package, project: project, name: project.full_path) }
      let_it_be(:maven_metadatum) { package.maven_metadatum }
      let_it_be(:package_file) { package.package_files.first }
      let_it_be(:deploy_token) { create(:deploy_token) }

      let(:headers_with_deploy_token) do
        {
          Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token
        }
      end

      it 'does not bypass the session' do
        expect(Gitlab::Auth::CurrentUserMode).not_to receive(:bypass_session!)

        get(api("/packages/maven/#{maven_metadatum.path}/#{package_file.file_name}"),
          headers: headers_with_deploy_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end
  end

  describe 'counter metrics', :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { project.first_owner }
    let_it_be(:http_router_rule_counter) { Gitlab::Metrics.counter(:gitlab_http_router_rule_total, 'description') }

    let(:perform_request) { get(api("/projects/#{project.id}", user), headers: headers) }

    context 'when the headers are present' do
      context 'for classify action' do
        let(:headers) do
          {
            'X-Gitlab-Http-Router-Rule-Action' => 'classify',
            'X-Gitlab-Http-Router-Rule-Type' => 'FIRST_CELL'
          }
        end

        it 'increments the counter' do
          expect { perform_request }
            .to change { http_router_rule_counter.get(rule_action: 'classify', rule_type: 'FIRST_CELL') }.by(1)
        end
      end

      context 'for proxy action' do
        let(:headers) do
          {
            'X-Gitlab-Http-Router-Rule-Action' => 'proxy'
          }
        end

        it 'increments the counter' do
          expect { perform_request }
            .to change { http_router_rule_counter.get(rule_action: 'proxy', rule_type: nil) }.by(1)
        end
      end
    end

    context 'for invalid action and type' do
      let(:headers) do
        {
          'X-Gitlab-Http-Router-Rule-Action' => 'invalid',
          'X-Gitlab-Http-Router-Rule-Type' => 'invalid'
        }
      end

      it 'does not increment the counter' do
        expect { perform_request }
          .to change { http_router_rule_counter.get(rule_action: 'invalid', rule_type: 'invalid') }.by(0)
      end
    end

    context 'when action is not present and type is present' do
      let(:headers) do
        {
          'X-Gitlab-Http-Router-Rule-Type' => 'FIRST_CELL'
        }
      end

      it 'does not increment the counter' do
        expect { perform_request }.to change {
          http_router_rule_counter.get(rule_action: nil, rule_type: 'FIRST_CELL')
        }.by(0)
      end
    end

    context 'when the headers are absent' do
      let(:headers) { {} }

      it 'does not increment the counter' do
        expect { perform_request }
          .to change { http_router_rule_counter.get(rule_action: nil, rule_type: nil) }.by(0)
      end
    end
  end

  describe 'logging', :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { project.first_owner }

    context 'when the endpoint is handled by the application' do
      context 'when the endpoint supports all possible fields' do
        it 'logs all application context fields and the route' do
          expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
            expect(data.stringify_keys).to include(
              'correlation_id' => an_instance_of(String),
              'meta.caller_id' => 'GET /api/:version/projects/:id/issues',
              'meta.remote_ip' => an_instance_of(String),
              'meta.project' => project.full_path,
              'meta.root_namespace' => project.namespace.full_path,
              'meta.user' => user.username,
              'meta.client_id' => a_string_matching(%r{\Auser/.+}),
              'meta.feature_category' => 'team_planning',
              'meta.http_router_rule_action' => 'classify',
              'meta.http_router_rule_type' => 'FIRST_CELL',
              'route' => '/api/:version/projects/:id/issues'
            )
          end

          get(api("/projects/#{project.id}/issues", user), headers: {
            'X-Gitlab-Http-Router-Rule-Action' => 'classify',
            'X-Gitlab-Http-Router-Rule-Type' => 'FIRST_CELL'
          })

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with an expired token' do
        let_it_be(:private_project) { create(:project) }
        let_it_be(:token) { create(:personal_access_token, :expired, user: user) }

        it 'logs all application context fields and the route' do
          expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
            expect(data.stringify_keys).to include(
              'correlation_id' => an_instance_of(String),
              'meta.caller_id' => 'GET /api/:version/projects/:id/issues',
              'meta.remote_ip' => an_instance_of(String),
              'meta.client_id' => a_string_matching(%r{\Aip/.+}),
              'meta.auth_fail_reason' => "token_expired",
              'meta.auth_fail_token_id' => "PersonalAccessToken/#{token.id}",
              'meta.feature_category' => 'team_planning',
              'route' => '/api/:version/projects/:id/issues'
            )
          end

          get(api("/projects/#{private_project.id}/issues", personal_access_token: token))

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      it 'skips context fields that do not apply' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys).to include(
            'correlation_id' => an_instance_of(String),
            'meta.caller_id' => 'GET /api/:version/broadcast_messages',
            'meta.remote_ip' => an_instance_of(String),
            'meta.client_id' => a_string_matching(%r{\Aip/.+}),
            'meta.feature_category' => 'notifications',
            'route' => '/api/:version/broadcast_messages'
          )

          expect(data.stringify_keys).not_to include('meta.project', 'meta.root_namespace', 'meta.user')
        end

        get(api('/broadcast_messages'))

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when there is an unsupported media type' do
      it 'logs the route and context metadata for the client' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys).to include(
            'correlation_id' => an_instance_of(String),
            'meta.remote_ip' => an_instance_of(String),
            'meta.client_id' => a_string_matching(%r{\Aip/.+}),
            'route' => '/api/:version/users/:id'
          )

          expect(data.stringify_keys).not_to include('meta.caller_id', 'meta.feature_category', 'meta.user')
        end

        put(api("/users/#{user.id}", user), params: { 'name' => 'Test' }, headers: { 'Content-Type' => 'image/png' })

        expect(response).to have_gitlab_http_status(:unsupported_media_type)
      end
    end

    context 'when there is an OPTIONS request' do
      it 'logs the route and context metadata for the client' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys).to include(
            'correlation_id' => an_instance_of(String),
            'meta.remote_ip' => an_instance_of(String),
            'meta.client_id' => a_string_matching(%r{\Auser/.+}),
            'meta.user' => user.username,
            'meta.feature_category' => 'user_profile',
            'route' => '/api/:version/users'
          )

          expect(data.stringify_keys).not_to include('meta.caller_id')
        end

        options(api('/users', user))

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when the API version is not matched' do
      it 'logs the route and context metadata for the client' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys).to include(
            'correlation_id' => an_instance_of(String),
            'meta.remote_ip' => an_instance_of(String),
            'meta.client_id' => a_string_matching(%r{\Aip/.+}),
            'route' => '/api/:version/*path'
          )

          expect(data.stringify_keys).not_to include('meta.caller_id', 'meta.user')
        end

        get('/api/v4_or_is_it')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when there is an unhandled exception for an anonymous request' do
      it 'logs all application context fields and the route' do
        expect(described_class::LOG_FORMATTER).to receive(:call) do |_severity, _datetime, _, data|
          expect(data.stringify_keys).to include(
            'correlation_id' => an_instance_of(String),
            'meta.caller_id' => 'GET /api/:version/broadcast_messages',
            'meta.remote_ip' => an_instance_of(String),
            'meta.client_id' => a_string_matching(%r{\Aip/.+}),
            'meta.feature_category' => 'notifications',
            'route' => '/api/:version/broadcast_messages'
          )

          expect(data.stringify_keys).not_to include('meta.project', 'meta.root_namespace', 'meta.user')
        end

        expect(System::BroadcastMessage).to receive(:all).and_raise('An error!')

        get(api('/broadcast_messages'))

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end
  end

  describe 'Marginalia comments' do
    context 'GET /user/:id' do
      let_it_be(:user) { create(:user) }

      let(:component_map) do
        {
          "application" => "test",
          "endpoint_id" => "GET /api/:version/users/:id"
        }
      end

      subject { ActiveRecord::QueryRecorder.new { get api("/users/#{user.id}", user) } }

      it 'generates a query that includes the expected annotations' do
        expect(subject.log.last).to match(/correlation_id:.*/)

        component_map.each do |component, value|
          expect(subject.log.last).to include("#{component}:#{value}")
        end
      end
    end
  end

  describe 'supported content-types' do
    context 'GET /user/:id.txt' do
      let_it_be(:user) { create(:user) }

      subject { get api("/users/#{user.id}.txt", user) }

      it 'returns application/json' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/json')
        expect(response.body).to include('{"id":')
      end
    end
  end

  describe 'content security policy header' do
    let_it_be(:user) { create(:user) }

    let(:csp) { nil }
    let(:report_only) { false }

    subject { get api("/users/#{user.id}", user) }

    before do
      allow(Rails.application.config).to receive(:content_security_policy).and_return(csp)
      allow(Rails.application.config).to receive(:content_security_policy_report_only).and_return(report_only)
    end

    context 'when CSP is not configured globally' do
      it 'does not set the CSP header' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Security-Policy']).to be_nil
      end
    end

    context 'when CSP is configured globally' do
      let(:csp) do
        ActionDispatch::ContentSecurityPolicy.new do |p|
          p.default_src :self
        end
      end

      it 'sets a stricter CSP header' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Security-Policy']).to eq("default-src 'none'")
      end

      context 'when report_only is true' do
        let(:report_only) { true }

        it 'does not set any CSP header' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Security-Policy']).to be_nil
          expect(response.headers['Content-Security-Policy-Report-Only']).to be_nil
        end
      end
    end
  end

  describe 'admin mode support' do
    let(:admin) { create(:admin) }

    subject do
      get api("/admin/clusters", personal_access_token: token)
      response
    end

    context 'with `admin_mode` scope' do
      let(:token) { create(:personal_access_token, user: admin, scopes: [:api, :admin_mode]) }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      context 'when admin mode setting is enabled' do
        it { is_expected.to have_gitlab_http_status(:ok) }
      end
    end

    context 'without `admin_mode` scope' do
      let(:token) { create(:personal_access_token, user: admin, scopes: [:api]) }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      context 'when admin mode setting is enabled' do
        it { is_expected.to have_gitlab_http_status(:forbidden) }
      end
    end
  end

  describe 'Handle Gitlab::Git::ResourceExhaustedError exception' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, creator: user) }

    before do
      project.add_maintainer(user)
      allow(Gitlab::GitalyClient).to receive(:call).with(any_args).and_raise(
        Gitlab::Git::ResourceExhaustedError.new("Upstream Gitaly has been exhausted. Try again later", 50)
      )
    end

    it 'returns 503 status and Retry-After header' do
      get api("/projects/#{project.id}/repository/commits", user)

      expect(response).to have_gitlab_http_status(:service_unavailable)
      expect(response.headers['Retry-After']).to be(50)
      expect(json_response).to eql(
        'message' => 'Upstream Gitaly has been exhausted. Try again later'
      )
    end
  end

  describe 'Grape::Exceptions::Base handler' do
    it 'returns 400 on JSON parse errors' do
      post api('/projects'),
        params: '{"test":"random_\$escaped/symbols\;here"}',
        headers: { 'content-type' => 'application/json' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'audit logging of requests with a specific token scope' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }
    let_it_be(:project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:path) { "/projects/#{issue.project.id}/issues/#{issue.iid}" }

    before_all do
      project.add_developer(user)
    end

    shared_examples 'audited request' do
      it 'adds audit log' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
          name: 'api_request_access_with_scope',
          message: "API request with token scopes [:ai_workflows] - GET /api/v4#{path}"
        })).and_call_original

        subject

        expect(response).to have_gitlab_http_status(status)
      end
    end

    shared_examples 'not audited request' do
      it "doesn't add audit log" do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        subject

        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'when endpoint allows token with ai_workflow scope' do
      subject { get api(path, oauth_access_token: token) }

      context 'when token with ai_workflows scope is used' do
        let(:status) { :ok }

        it_behaves_like 'audited request'

        context 'when request fails' do
          let_it_be(:path) { "/projects/#{issue.project.id}/issues/#{non_existing_record_id}" }
          let(:status) { :not_found }

          it_behaves_like 'audited request'
        end
      end

      context 'when token with ai_workflows scope is not used' do
        let_it_be(:token) { create(:oauth_access_token, user: user, scopes: [:api]) }
        let(:status) { :ok }

        it_behaves_like 'not audited request'
      end
    end

    context "when endpoint doesn't allow token with ai_workflow scope" do
      subject { delete api(path, oauth_access_token: token) }

      let(:status) { :forbidden }

      it_behaves_like 'not audited request'
    end
  end
end
