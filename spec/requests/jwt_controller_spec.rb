# frozen_string_literal: true

require 'spec_helper'

describe JwtController do
  let(:service) { double(execute: {}) }
  let(:service_class) { double(new: service) }
  let(:service_name) { 'test' }
  let(:parameters) { { service: service_name } }

  before do
    stub_const('JwtController::SERVICES', service_name => service_class)
  end

  context 'existing service' do
    subject! { get '/jwt/auth', params: parameters }

    it { expect(response).to have_gitlab_http_status(200) }

    context 'returning custom http code' do
      let(:service) { double(execute: { http_status: 505 }) }

      it { expect(response).to have_gitlab_http_status(505) }
    end
  end

  context 'when using authenticated request' do
    context 'using CI token' do
      let(:build) { create(:ci_build, :running) }
      let(:project) { build.project }
      let(:headers) { { authorization: credentials('gitlab-ci-token', build.token) } }

      context 'project with enabled CI' do
        subject! { get '/jwt/auth', params: parameters, headers: headers }

        it { expect(service_class).to have_received(:new).with(project, nil, ActionController::Parameters.new(parameters).permit!) }
      end

      context 'project with disabled CI' do
        before do
          project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
        end

        subject! { get '/jwt/auth', params: parameters, headers: headers }

        it { expect(response).to have_gitlab_http_status(401) }
      end

      context 'using personal access tokens' do
        let(:user) { create(:user) }
        let(:pat) { create(:personal_access_token, user: user, scopes: ['read_registry']) }
        let(:headers) { { authorization: credentials('personal_access_token', pat.token) } }

        before do
          stub_container_registry_config(enabled: true)
        end

        subject! { get '/jwt/auth', params: parameters, headers: headers }

        it 'authenticates correctly' do
          expect(response).to have_gitlab_http_status(200)
          expect(service_class).to have_received(:new).with(nil, user, ActionController::Parameters.new(parameters).permit!)
        end
      end
    end

    context 'using User login' do
      let(:user) { create(:user) }
      let(:headers) { { authorization: credentials(user.username, user.password) } }

      subject! { get '/jwt/auth', params: parameters, headers: headers }

      it { expect(service_class).to have_received(:new).with(nil, user, ActionController::Parameters.new(parameters).permit!) }

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
          ActionController::Parameters.new({ service: service_name, scopes: %w(scope1 scope2) }).permit!
        end

        it { expect(service_class).to have_received(:new).with(nil, user, service_parameters) }
      end

      context 'when user has 2FA enabled' do
        let(:user) { create(:user, :two_factor) }

        context 'without personal token' do
          it 'rejects the authorization attempt' do
            expect(response).to have_gitlab_http_status(401)
            expect(response.body).to include('You must use a personal access token with \'api\' scope for Git over HTTP')
          end
        end

        context 'with personal token' do
          let(:access_token) { create(:personal_access_token, user: user) }
          let(:headers) { { authorization: credentials(user.username, access_token.token) } }

          it 'accepts the authorization attempt' do
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      it 'does not cause session based checks to be activated' do
        expect(Gitlab::Session).not_to receive(:with_session)

        get '/jwt/auth', params: parameters, headers: headers

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'using invalid login' do
      let(:headers) { { authorization: credentials('invalid', 'password') } }

      context 'when internal auth is enabled' do
        it 'rejects the authorization attempt' do
          get '/jwt/auth', params: parameters, headers: headers

          expect(response).to have_gitlab_http_status(401)
          expect(response.body).not_to include('You must use a personal access token with \'api\' scope for Git over HTTP')
        end
      end

      context 'when internal auth is disabled' do
        it 'rejects the authorization attempt with personal access token message' do
          allow_next_instance_of(ApplicationSetting) do |instance|
            allow(instance).to receive(:password_authentication_enabled_for_git?) { false }
          end
          get '/jwt/auth', params: parameters, headers: headers

          expect(response).to have_gitlab_http_status(401)
          expect(response.body).to include('You must use a personal access token with \'api\' scope for Git over HTTP')
        end
      end
    end
  end

  context 'when using unauthenticated request' do
    it 'accepts the authorization attempt' do
      get '/jwt/auth', params: parameters

      expect(response).to have_gitlab_http_status(200)
    end

    it 'allows read access' do
      expect(service).to receive(:execute).with(authentication_abilities: Gitlab::Auth.read_only_authentication_abilities)

      get '/jwt/auth', params: parameters
    end
  end

  context 'unknown service' do
    subject! { get '/jwt/auth', params: { service: 'unknown' } }

    it { expect(response).to have_gitlab_http_status(404) }
  end

  def credentials(login, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end
end
