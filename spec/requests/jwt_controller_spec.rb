require 'spec_helper'

describe JwtController do
  let(:services) { { 'test' => TestService } }
  let(:parameters) { { service: 'test' } }
  let(:ok_status) { { status: 'OK' } }

  before { allow_any_instance_of(JwtController).to receive(:SERVICES).and_return services }

  context 'existing service' do
    before { expect_any_instance_of(TestService).to receive(:execute).and_return(ok_status) }

    subject! { get '/jwt/auth', parameters }

    it { expect(response.status).to eq(200) }
  end

  context 'when using authorized request' do
    context 'using CI token' do
      let(:project) { create(:empty_project, runners_token: 'token', builds_enabled: builds_enabled) }
      let(:headers) { { HTTP_AUTHENTICATION: authorize('gitlab-ci-token', project.runners_token) } }

      context 'project with enabled CI' do
        let(:builds_enabled) { true }

        it do
          expect(TestService).to receive(:new).with(project, nil, parameters).and_call_original

          get '/jwt/auth', parameters, headers
        end
      end

      context 'project with disabled CI' do
        let(:builds_enabled) { false }

        it do
          expect(TestService).to receive(:new).with(project, nil, parameters).and_call_original

          get '/jwt/auth', parameters, headers
        end
      end
    end

    context 'using User login' do
      let(:user) { create(:user) }
      let(:headers) { { HTTP_AUTHENTICATION: authorize('user', 'password') } }

      before { expect_any_instance_of(Gitlab::Auth).to receive(:find).with('user', 'password').and_return(user) }

      it do
        expect(TestService).to receive(:new).with(nil, user, parameters).and_call_original

        get '/jwt/auth', parameters, headers
      end
    end

    context 'using invalid login' do
      let(:headers) { { HTTP_AUTHENTICATION: authorize('invalid', 'password') } }

      subject! { get '/jwt/auth', parameters, headers }

      it { expect(response.status).to eq(403) }
    end
  end

  context 'unknown service' do
    subject! { get '/jwt/auth', service: 'unknown' }

    it { expect(response.status).to eq(404) }
  end

  def authorize(login, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end

  class TestService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params = {})
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
      { status: 'OK' }
    end
  end
end
