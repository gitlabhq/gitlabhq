require 'spec_helper'

describe JwtController do
  let(:service) { double(execute: {}) }
  let(:service_class) { double(new: service) }
  let(:service_name) { 'test' }
  let(:parameters) { { service: service_name } }

  before { stub_const('JwtController::SERVICES', service_name => service_class) }

  context 'existing service' do
    subject! { get '/jwt/auth', parameters }

    it { expect(response).to have_http_status(200) }

    context 'returning custom http code' do
      let(:service) { double(execute: { http_status: 505 }) }

      it { expect(response).to have_http_status(505) }
    end
  end

  context 'when using authorized request' do
    context 'using CI token' do
      let(:build) { create(:ci_build, :running) }
      let(:project) { build.project }
      let(:headers) { { authorization: credentials('gitlab-ci-token', build.token) } }

      context 'project with enabled CI' do
        subject! { get '/jwt/auth', parameters, headers }

        it { expect(service_class).to have_received(:new).with(project, nil, parameters) }
      end

      context 'project with disabled CI' do
        before do
          project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
        end

        subject! { get '/jwt/auth', parameters, headers }

        it { expect(response).to have_http_status(403) }
      end
    end

    context 'using User login' do
      let(:user) { create(:user) }
      let(:headers) { { authorization: credentials(user.username, user.password) } }

      subject! { get '/jwt/auth', parameters, headers }

      it { expect(service_class).to have_received(:new).with(nil, user, parameters) }

      context 'when user has 2FA enabled' do
        let(:user) { create(:user, :two_factor) }

        context 'without personal token' do
          it 'rejects the authorization attempt' do
            expect(response).to have_http_status(401)
            expect(response.body).to include('You have 2FA enabled, please use a personal access token for Git over HTTP')
          end
        end

        context 'with personal token' do
          let(:access_token) { create(:personal_access_token, user: user) }
          let(:headers) { { authorization: credentials(user.username, access_token.token) } }

          it 'rejects the authorization attempt' do
            expect(response).to have_http_status(200)
          end
        end
      end
    end

    context 'using invalid login' do
      let(:headers) { { authorization: credentials('invalid', 'password') } }

      subject! { get '/jwt/auth', parameters, headers }

      it { expect(response).to have_http_status(403) }
    end
  end

  context 'unknown service' do
    subject! { get '/jwt/auth', service: 'unknown' }

    it { expect(response).to have_http_status(404) }
  end

  def credentials(login, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end
end
