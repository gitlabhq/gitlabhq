require 'spec_helper'

describe JwtController do
  let(:service) { double(execute: {}) }
  let(:service_class) { double(new: service) }
  let(:service_name) { 'test' }
  let(:parameters) { { service: service_name } }

  before { stub_const('JwtController::SERVICES', service_name => service_class) }

  context 'existing service' do
    subject! { get '/jwt/auth', parameters }

    it { expect(response.status).to eq(200) }

    context 'returning custom http code' do
      let(:service) { double(execute: { http_status: 505 }) }

      it { expect(response.status).to eq(505) }
    end
  end

  context 'when using authorized request' do
    context 'using CI token' do
      let(:project) { create(:empty_project, runners_token: 'token', builds_enabled: builds_enabled) }
      let(:headers) { { authorization: credentials('gitlab-ci-token', project.runners_token) } }

      subject! { get '/jwt/auth', parameters, headers }

      context 'project with enabled CI' do
        let(:builds_enabled) { true }

        it { expect(service_class).to have_received(:new).with(project, nil, parameters) }
      end

      context 'project with disabled CI' do
        let(:builds_enabled) { false }

        it { expect(response.status).to eq(403) }
      end
    end

    context 'using User login' do
      let(:user) { create(:user) }
      let(:headers) { { authorization: credentials('user', 'password') } }

      before { expect_any_instance_of(Gitlab::Auth).to receive(:find).with('user', 'password').and_return(user) }

      subject! { get '/jwt/auth', parameters, headers }

      it { expect(service_class).to have_received(:new).with(nil, user, parameters) }
    end

    context 'using invalid login' do
      let(:headers) { { authorization: credentials('invalid', 'password') } }

      subject! { get '/jwt/auth', parameters, headers }

      it { expect(response.status).to eq(403) }
    end
  end

  context 'unknown service' do
    subject! { get '/jwt/auth', service: 'unknown' }

    it { expect(response.status).to eq(404) }
  end

  def credentials(login, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end
end
