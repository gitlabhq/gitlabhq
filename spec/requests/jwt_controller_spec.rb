# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JwtController, feature_category: :system_access do
  include_context 'parsed logs'

  let(:service) { double(execute: {}) }
  let(:service_class) { Auth::ContainerRegistryAuthenticationService }
  let(:service_name) { 'container_registry' }
  let(:parameters) { { service: service_name } }

  before do
    allow(service_class).to receive(:new).and_return(service)
  end

  shared_examples 'user logging' do
    it 'logs username and ID' do
      expect(log_data['username']).to eq(user.username)
      expect(log_data['user_id']).to eq(user.id)
      expect(log_data['meta.user']).to eq(user.username)
    end
  end

  shared_examples 'a token that expires today' do
    let(:pat) { create(:personal_access_token, user: user, scopes: ['api'], expires_at: Date.today) }
    let(:headers) { { authorization: credentials('personal_access_token', pat.token) } }

    it 'fails authentication' do
      expect(::Gitlab::AuthLogger).to receive(:warn).with(
        hash_including(message: 'JWT authentication failed', http_user: 'personal_access_token')
      ).and_call_original

      get '/jwt/auth', params: parameters, headers: headers

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples "with invalid credentials" do
    it "returns a generic error message" do
      subject

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(json_response).to eq(
        {
          "errors" => [{
            "code" => "UNAUTHORIZED",
            "message" => "HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped. See http://www.example.com/help/user/profile/account/two_factor_authentication_troubleshooting.md#error-http-basic-access-denied-if-a-password-was-provided-for-git-authentication-"
          }]
        }
      )
    end
  end

  context 'POST /jwt/auth' do
    it 'returns 404' do
      post '/jwt/auth'

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'POST /jwt/auth when in maintenance mode' do
    before do
      stub_maintenance_mode_setting(true)
    end

    it 'returns 404' do
      post '/jwt/auth'

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'authenticating against container registry' do
    context 'existing service' do
      subject! { get '/jwt/auth', params: parameters }

      it { expect(response).to have_gitlab_http_status(:ok) }

      context 'returning custom http code' do
        let(:service) { double(execute: { http_status: 505 }) }

        it { expect(response).to have_gitlab_http_status(:http_version_not_supported) }
      end
    end

    context 'when using authenticated request' do
      shared_examples 'rejecting a blocked user' do
        context 'with blocked user' do
          let(:user) { create(:user, :blocked) }

          it_behaves_like 'with invalid credentials'
        end
      end

      context 'using CI token' do
        let(:user) { create(:user) }
        let(:build) { create(:ci_build, :running, user: user) }
        let(:project) { build.project }
        let(:headers) { { authorization: credentials('gitlab-ci-token', build.token) } }

        context 'project with enabled CI' do
          subject! { get '/jwt/auth', params: parameters, headers: headers }

          it { expect(service_class).to have_received(:new).with(project, user, ActionController::Parameters.new(parameters.merge(auth_type: :build)).permit!) }

          it_behaves_like 'user logging'
        end

        context 'project with disabled CI' do
          before do
            project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
          end

          subject! { get '/jwt/auth', params: parameters, headers: headers }

          it { expect(response).to have_gitlab_http_status(:unauthorized) }
        end

        context 'using deploy tokens' do
          let(:deploy_token) { create(:deploy_token, read_registry: true, projects: [project]) }
          let(:headers) { { authorization: credentials(deploy_token.username, deploy_token.token) } }

          subject! { get '/jwt/auth', params: parameters, headers: headers }

          it 'authenticates correctly' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(service_class).to have_received(:new)
              .with(
                nil,
                nil,
                ActionController::Parameters.new(parameters.merge(deploy_token: deploy_token, auth_type: :deploy_token)).permit!
              )
          end

          it 'does not log a user' do
            expect(log_data.keys).not_to include(%w[username user_id])
          end
        end

        context 'using personal access tokens' do
          let(:pat) { create(:personal_access_token, user: user, scopes: ['read_registry']) }
          let(:headers) { { authorization: credentials('personal_access_token', pat.token) } }

          before do
            stub_container_registry_config(enabled: true)
          end

          subject! { get '/jwt/auth', params: parameters, headers: headers }

          it 'authenticates correctly' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(service_class).to have_received(:new)
              .with(
                nil,
                user,
                ActionController::Parameters.new(parameters.merge(auth_type: :personal_access_token, raw_token: pat.token)).permit!
              )
          end

          it_behaves_like 'rejecting a blocked user'
          it_behaves_like 'user logging'
          it_behaves_like 'a token that expires today'
        end
      end

      context 'using User login' do
        let(:user) { create(:user) }
        let(:headers) { { authorization: credentials(user.username, user.password) } }

        subject! { get '/jwt/auth', params: parameters, headers: headers }

        it { expect(service_class).to have_received(:new).with(nil, user, ActionController::Parameters.new(parameters.merge(auth_type: :gitlab_or_ldap)).permit!) }

        it_behaves_like 'rejecting a blocked user'

        context 'when passing a flat array of scopes' do
          # We use this trick to make rails to generate a query_string:
          # scope=scope1&scope=scope2
          # It works because :scope and 'scope' are the same as string, but different objects
          let(:parameters) do
            {
              :service => service_name,
              :scope => 'scope1',
              'scope' => 'scope2'
            }
          end

          let(:service_parameters) do
            ActionController::Parameters.new({ service: service_name, scopes: %w[scope1 scope2] }).permit!
          end

          it { expect(service_class).to have_received(:new).with(nil, user, service_parameters.merge(auth_type: :gitlab_or_ldap)) }

          it_behaves_like 'user logging'
        end

        context 'when passing a space-delimited list of scopes' do
          let(:parameters) do
            {
              service: service_name,
              scope: 'scope1 scope2'
            }
          end

          let(:service_parameters) do
            ActionController::Parameters.new({ service: service_name, scopes: %w[scope1 scope2] }).permit!
          end

          it { expect(service_class).to have_received(:new).with(nil, user, service_parameters.merge(auth_type: :gitlab_or_ldap)) }
        end

        context 'when user has 2FA enabled' do
          let(:user) { create(:user, :two_factor) }

          context 'without personal token' do
            it_behaves_like 'with invalid credentials'
          end

          context 'with personal token' do
            let(:access_token) { create(:personal_access_token, user: user) }
            let(:headers) { { authorization: credentials(user.username, access_token.token) } }

            it 'accepts the authorization attempt' do
              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end

        it 'does not cause session based checks to be activated' do
          expect(Gitlab::Session).not_to receive(:with_session)

          get '/jwt/auth', params: parameters, headers: headers

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when the user is admin' do
          let(:admin) { create(:admin) }
          let(:access_token) { create(:personal_access_token, user: admin) }
          let(:headers) { { authorization: credentials(admin.username, access_token.token) } }

          # We are bypassing admin mode for registry operations
          # since that should not matter for data based operations
          context 'when admin mode is enabled', :enable_admin_mode do
            it 'accepts the authorization attempt' do
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'when admin mode is disabled' do
            it 'accepts the authorization attempt' do
              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end

      context 'using invalid login' do
        let(:headers) { { authorization: credentials('invalid', 'password') } }
        let(:subject) { get '/jwt/auth', params: parameters, headers: headers }

        context 'when internal auth is enabled' do
          it_behaves_like 'with invalid credentials'
        end

        context 'when internal auth is disabled' do
          before do
            stub_application_setting(password_authentication_enabled_for_git: false)
          end

          it_behaves_like 'with invalid credentials'
        end
      end
    end

    context 'when using unauthenticated request' do
      it 'accepts the authorization attempt' do
        get '/jwt/auth', params: parameters

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'allows read access' do
        expect(service).to receive(:execute).with(authentication_abilities: Gitlab::Auth.read_only_authentication_abilities)

        get '/jwt/auth', params: parameters
      end
    end

    context 'unknown service' do
      subject! { get '/jwt/auth', params: { service: 'unknown' } }

      it { expect(response).to have_gitlab_http_status(:not_found) }
    end

    def credentials(login, password)
      ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
    end
  end

  context 'authenticating against dependency proxy' do
    let_it_be(:user) { create(:user) }
    let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :private, group: group) }
    let_it_be(:bot_user) { create(:user, :project_bot) }
    let_it_be(:group_access_token) { create(:personal_access_token, :dependency_proxy_scopes, user: bot_user) }
    let_it_be(:group_deploy_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }
    let_it_be(:gdeploy_token) { create(:group_deploy_token, deploy_token: group_deploy_token, group: group) }
    let_it_be(:project_deploy_token) { create(:deploy_token, :project, :dependency_proxy_scopes) }
    let_it_be(:pdeploy_token) { create(:project_deploy_token, deploy_token: project_deploy_token, project: project) }
    let_it_be(:service_name) { 'dependency_proxy' }

    let(:headers) { { authorization: credentials(credential_user, credential_password) } }
    let(:params) { { account: credential_user, client_id: 'docker', offline_token: true, service: service_name } }

    before do
      stub_config(dependency_proxy: { enabled: true })
    end

    subject { get '/jwt/auth', params: params, headers: headers }

    shared_examples 'with valid credentials' do
      it 'returns token successfully' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['token']).to be_present
      end
    end

    context 'with personal access token' do
      let(:credential_user) { nil }
      let(:credential_password) { personal_access_token.token }

      it_behaves_like 'with valid credentials'
      it_behaves_like 'a token that expires today'
    end

    context 'with user credentials token' do
      let(:credential_user) { user.username }
      let(:credential_password) { user.password }

      it_behaves_like 'with valid credentials'
    end

    context 'with group access token' do
      let(:credential_user) { group_access_token.user.username }
      let(:credential_password) { group_access_token.token }

      context 'with the required scopes' do
        it_behaves_like 'with valid credentials'
        it_behaves_like 'a token that expires today'

        context 'revoked' do
          before do
            group_access_token.update!(revoked: true)
          end

          it_behaves_like 'returning response status', :unauthorized
        end

        context 'expired' do
          before do
            group_access_token.update!(expires_at: Date.yesterday)
          end

          it_behaves_like 'returning response status', :unauthorized
        end
      end

      context 'without the required scopes' do
        before do
          group_access_token.update!(scopes: [::Gitlab::Auth::READ_REPOSITORY_SCOPE])
        end

        it_behaves_like 'returning response status', :forbidden

        context 'packages_dependency_proxy_containers_scope_check disabled' do
          before do
            stub_feature_flags(packages_dependency_proxy_containers_scope_check: false)
          end

          it_behaves_like 'with valid credentials'
        end
      end
    end

    context 'with group deploy token' do
      let(:credential_user) { group_deploy_token.username }
      let(:credential_password) { group_deploy_token.token }

      it_behaves_like 'with valid credentials'
    end

    context 'with job token' do
      let_it_be_with_reload(:job) { create(:ci_build, user: user, status: :running, project: project) }
      let_it_be(:credential_user) { 'gitlab-ci-token' }

      let(:credential_password) { job.token }

      it_behaves_like 'with valid credentials'
    end

    context 'with project deploy token' do
      let(:credential_user) { project_deploy_token.username }
      let(:credential_password) { project_deploy_token.token }

      it_behaves_like 'returning response status', :forbidden
    end

    context 'with revoked group deploy token' do
      let(:credential_user) { group_deploy_token.username }
      let(:credential_password) { project_deploy_token.token }

      before do
        group_deploy_token.update_column(:revoked, true)
      end

      it_behaves_like 'returning response status', :unauthorized
    end

    context 'with group deploy token with insufficient scopes' do
      let(:credential_user) { group_deploy_token.username }
      let(:credential_password) { project_deploy_token.token }

      before do
        group_deploy_token.update_column(:write_registry, false)
      end

      it_behaves_like 'returning response status', :unauthorized
    end

    context 'with invalid credentials' do
      let(:credential_user) { 'foo' }
      let(:credential_password) { 'bar' }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  def credentials(login, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end
end
