# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../config/initializers/sentry'

RSpec.describe API::Helpers, :enable_admin_mode, feature_category: :system_access do
  include API::APIGuard::HelperMethods
  include described_class
  include TermsHelper

  let_it_be(:organization) { create(:organization) }
  let_it_be(:user, reload: true) { create(:user, organizations: [organization]) }

  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }

  let(:csrf_token) { SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH) }
  let(:env) do
    {
      'rack.input' => '',
      'rack.session' => {
        _csrf_token: csrf_token
      },
      'REQUEST_METHOD' => 'GET',
      'CONTENT_TYPE' => 'text/plain;charset=utf-8'
    }
  end

  let(:header) {}
  let(:request) { Grape::Request.new(env) }
  let(:params) { request.params }

  before do
    allow_any_instance_of(self.class).to receive(:options).and_return({})

    allow(env['rack.session']).to receive(:enabled?).and_return(true)
    allow(env['rack.session']).to receive(:loaded?).and_return(true)
  end

  def warden_authenticate_returns(value)
    warden = double("warden", authenticate: value)
    env['warden'] = warden
  end

  def error!(message, status, header)
    raise StandardError, "#{status} - #{message}"
  end

  def set_param(key, value)
    request.update_param(key, value)
  end

  describe ".current_user" do
    subject { current_user }

    describe "Warden authentication", :allow_forgery_protection do
      context "with invalid credentials" do
        context "GET request" do
          before do
            env['REQUEST_METHOD'] = 'GET'
          end

          it { is_expected.to be_nil }
        end
      end

      context "with valid credentials" do
        before do
          warden_authenticate_returns user
        end

        context "GET request" do
          before do
            env['REQUEST_METHOD'] = 'GET'
          end

          it { is_expected.to eq(user) }

          it 'sets the environment with data of the current user' do
            subject

            expect(env[API::Helpers::API_USER_ENV]).to eq({ user_id: subject.id, username: subject.username })
          end
        end

        context "HEAD request" do
          before do
            env['REQUEST_METHOD'] = 'HEAD'
          end

          it { is_expected.to eq(user) }

          context 'when user should have 2fa enabled' do
            before do
              allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)
              allow_next_instance_of(Gitlab::Auth::TwoFactorAuthVerifier) do |verifier|
                allow(verifier).to receive(:two_factor_grace_period_expired?).and_return(true)
              end
            end

            context 'when 2fa is not enabled' do
              it { is_expected.to be_nil }
            end

            context 'when 2fa is enabled' do
              before do
                allow(user).to receive(:two_factor_enabled?).and_return(true)
              end

              it { is_expected.to eq(user) }
            end
          end
        end

        context "PUT request" do
          before do
            env['REQUEST_METHOD'] = 'PUT'
          end

          context 'without CSRF token' do
            it { is_expected.to be_nil }
          end

          context 'with CSRF token' do
            before do
              env['HTTP_X_CSRF_TOKEN'] = csrf_token
            end

            it { is_expected.to eq(user) }
          end
        end

        context "POST request" do
          before do
            env['REQUEST_METHOD'] = 'POST'
          end

          context 'without CSRF token' do
            it { is_expected.to be_nil }
          end

          context 'with CSRF token' do
            before do
              env['HTTP_X_CSRF_TOKEN'] = csrf_token
            end

            it { is_expected.to eq(user) }
          end
        end

        context "DELETE request" do
          before do
            env['REQUEST_METHOD'] = 'DELETE'
          end

          context 'without CSRF token' do
            it { is_expected.to be_nil }
          end

          context 'with CSRF token' do
            before do
              env['HTTP_X_CSRF_TOKEN'] = csrf_token
            end

            it { is_expected.to eq(user) }
          end
        end
      end
    end

    describe "when authenticating using a user's personal access tokens" do
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      it "returns a 401 response for an invalid token" do
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = 'invalid token'

        expect { current_user }.to raise_error(/401/)
      end

      it "returns a 403 response for a user without access" do
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(false)

        expect { current_user }.to raise_error(/403/)
      end

      it 'returns a 403 response for a user who is blocked' do
        user.block!
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect { current_user }.to raise_error(/403/)
      end

      context 'when terms are enforced' do
        before do
          enforce_terms
          env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        end

        it 'returns a 403 when a user has not accepted the terms' do
          expect { current_user }.to raise_error(/must accept the Terms of Service/)
        end

        it 'sets the current user when the user accepted the terms' do
          accept_terms(user)

          expect(current_user).to eq(user)
        end
      end

      it "sets current_user" do
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        expect(current_user).to eq(user)
      end

      it "does not allow tokens without the appropriate scope" do
        personal_access_token = create(:personal_access_token, user: user, scopes: ['read_user'])
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect { current_user }.to raise_error Gitlab::Auth::InsufficientScopeError
      end

      it 'does not allow revoked tokens' do
        personal_access_token.revoke!
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect { current_user }.to raise_error Gitlab::Auth::RevokedError
      end

      it 'does not allow expired tokens' do
        personal_access_token.update!(expires_at: 1.day.ago)
        env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect { current_user }.to raise_error Gitlab::Auth::ExpiredError
      end

      context 'when impersonation is disabled' do
        let(:personal_access_token) { create(:personal_access_token, :impersonation, user: user) }

        before do
          stub_config_setting(impersonation_enabled: false)
          env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        end

        it 'does not allow impersonation tokens' do
          expect { current_user }.to raise_error Gitlab::Auth::ImpersonationDisabled
        end
      end
    end

    describe "when authenticating using a job token" do
      let_it_be(:job, reload: true) do
        create(:ci_build, user: user, status: :running)
      end

      let(:route_authentication_setting) { {} }

      before do
        allow_any_instance_of(self.class).to receive(:route_authentication_setting)
          .and_return(route_authentication_setting)
      end

      context 'when route is allowed to be authenticated' do
        let(:route_authentication_setting) { { job_token_allowed: true } }

        it "returns a 401 response for an invalid token" do
          env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = 'invalid token'

          expect { current_user }.to raise_error(/401/)
        end

        it "returns a 401 response for a job that's not running" do
          job.update!(status: :success)
          env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = job.token

          expect { current_user }.to raise_error(/401/)
        end

        it "returns a 403 response for a user without access" do
          env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = job.token
          allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(false)

          expect { current_user }.to raise_error(/403/)
        end

        it 'returns a 403 response for a user who is blocked' do
          user.block!
          env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = job.token

          expect { current_user }.to raise_error(/403/)
        end

        it "sets current_user" do
          env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = job.token

          expect(current_user).to eq(user)
        end
      end

      context 'when route is not allowed to be authenticated' do
        let(:route_authentication_setting) { { job_token_allowed: false } }

        it "sets current_user to nil" do
          env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = job.token
          allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(true)

          expect(current_user).to be_nil
        end
      end
    end
  end

  describe '.set_current_organization' do
    context 'when user argument is omitted' do
      before do
        allow(self).to receive(:current_user).and_return(user)
      end

      it 'sets Current.organization using current_user' do
        set_current_organization

        expect(Current.organization).to eq(organization)
      end
    end

    context 'when user is passed' do
      let(:other_user) { create(:user, organizations: [create(:organization)]) }

      it 'sets Current.organization' do
        set_current_organization(user: other_user)

        expect(Current.organization).to eq(other_user.organizations.first)
      end
    end
  end

  describe '.handle_api_exception' do
    before do
      allow_any_instance_of(self.class).to receive(:rack_response)

      stub_sentry_settings

      expect(Gitlab::ErrorTracking).to receive(:sentry_dsn).and_return(Gitlab.config.sentry.dsn)
      Gitlab::ErrorTracking.configure
    end

    it 'does not report a MethodNotAllowed exception to Sentry' do
      exception = Grape::Exceptions::MethodNotAllowed.new({ 'X-GitLab-Test' => '1' })
      allow(exception).to receive(:backtrace).and_return(caller)

      expect(Gitlab::ErrorTracking).not_to receive(:track_exception).with(exception)

      handle_api_exception(exception)
    end

    it 'does report RuntimeError to Sentry' do
      exception = RuntimeError.new('test error')
      allow(exception).to receive(:backtrace).and_return(caller)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception)

      Labkit::Correlation::CorrelationId.use_id('new-correlation-id') do
        handle_api_exception(exception)
      end
    end

    context 'with a personal access token given' do
      let(:token) { create(:personal_access_token, scopes: ['api'], user: user) }

      # Regression test for https://gitlab.com/gitlab-org/gitlab-foss/issues/38571
      it 'does not raise an additional exception because of missing `request`' do
        # We need to stub at a lower level than #sentry_enabled? otherwise
        # Sentry is not enabled when the request below is made, and the test
        # would pass even without the fix
        expect(ProjectsFinder).to receive(:new).and_raise('Runtime Error!')

        get api('/projects', personal_access_token: token)

        # The 500 status is expected as we're testing a case where an exception
        # is raised, but Grape shouldn't raise an additional exception
        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(json_response['message']).not_to include("undefined local variable or method `request'")
        expect(json_response['message']).to start_with("\nRuntimeError (Runtime Error!):")
      end
    end
  end

  describe '.authenticate_non_get!' do
    %w[HEAD GET].each do |method_name|
      context "method is #{method_name}" do
        before do
          expect_any_instance_of(self.class).to receive(:route).and_return(double(request_method: method_name))
        end

        it 'does not raise an error' do
          expect_any_instance_of(self.class).not_to receive(:authenticate!)

          expect { authenticate_non_get! }.not_to raise_error
        end
      end
    end

    %w[POST PUT PATCH DELETE].each do |method_name|
      context "method is #{method_name}" do
        before do
          expect_any_instance_of(self.class).to receive(:route).and_return(double(request_method: method_name))
        end

        it 'calls authenticate!' do
          expect_any_instance_of(self.class).to receive(:authenticate!)

          authenticate_non_get!
        end
      end
    end
  end

  describe '.authenticate!' do
    context 'current_user is nil' do
      before do
        expect_any_instance_of(self.class).to receive(:current_user).and_return(nil)
      end

      it 'returns a 401 response' do
        expect { authenticate! }.to raise_error(/401/)

        expect(env[described_class::API_RESPONSE_STATUS_CODE]).to eq(401)
      end
    end

    context 'current_user is present' do
      let(:user) { build(:user) }

      before do
        expect_any_instance_of(self.class).to receive(:current_user).and_return(user)
      end

      it 'does not raise an error' do
        expect { authenticate! }.not_to raise_error

        expect(env[described_class::API_RESPONSE_STATUS_CODE]).to be_nil
      end
    end
  end

  context 'sudo' do
    include_context 'custom session'

    shared_examples 'successful sudo' do
      it 'sets current_user' do
        expect(current_user).to eq(user)
      end

      it 'sets sudo?' do
        expect(sudo?).to be_truthy
      end
    end

    shared_examples 'sudo' do
      context 'when admin' do
        before do
          token.user = admin
          token.save!
        end

        context 'when token has sudo scope' do
          before do
            token.scopes = %w[sudo]
            token.save!
          end

          context 'when user exists' do
            context 'when using header' do
              context 'when providing username' do
                before do
                  env[API::Helpers::SUDO_HEADER] = user.username
                end

                it_behaves_like 'successful sudo'
              end

              context 'when providing username (case insensitive)' do
                before do
                  env[API::Helpers::SUDO_HEADER] = user.username.upcase
                end

                it_behaves_like 'successful sudo'
              end

              context 'when providing user ID' do
                before do
                  env[API::Helpers::SUDO_HEADER] = user.id.to_s
                end

                it_behaves_like 'successful sudo'
              end
            end

            context 'when using param' do
              context 'when providing username' do
                before do
                  set_param(API::Helpers::SUDO_PARAM, user.username)
                end

                it_behaves_like 'successful sudo'
              end

              context 'when providing username (case insensitive)' do
                before do
                  set_param(API::Helpers::SUDO_PARAM, user.username.upcase)
                end

                it_behaves_like 'successful sudo'
              end

              context 'when providing user ID' do
                before do
                  set_param(API::Helpers::SUDO_PARAM, user.id.to_s)
                end

                it_behaves_like 'successful sudo'
              end
            end
          end

          context 'when user does not exist' do
            before do
              set_param(API::Helpers::SUDO_PARAM, 'nonexistent')
            end

            it 'raises an error' do
              expect { current_user }.to raise_error(/User with ID or username 'nonexistent' Not Found/)
            end
          end
        end

        context 'when token does not have sudo scope' do
          before do
            token.scopes = %w[api]
            token.save!

            set_param(API::Helpers::SUDO_PARAM, user.id.to_s)
          end

          it 'raises an error' do
            expect { current_user }.to raise_error Gitlab::Auth::InsufficientScopeError
          end
        end
      end

      context 'when not admin' do
        before do
          token.user = user
          token.save!

          set_param(API::Helpers::SUDO_PARAM, user.id.to_s)
        end

        it 'raises an error' do
          expect { current_user }.to raise_error(/Must be admin to use sudo/)
        end
      end
    end

    context 'using an OAuth token' do
      let(:token) { create(:oauth_access_token) }

      before do
        env['HTTP_AUTHORIZATION'] = "Bearer #{token.plaintext_token}"
      end

      it_behaves_like 'sudo'
    end

    context 'using a personal access token' do
      let(:token) { create(:personal_access_token) }

      context 'passed as param' do
        before do
          set_param(Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_PARAM, token.token)
        end

        it_behaves_like 'sudo'
      end

      context 'passed as header' do
        before do
          env[Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER] = token.token
        end

        it_behaves_like 'sudo'
      end
    end

    context 'using warden authentication' do
      before do
        allow(session).to receive(:enabled?).and_return(true)
        allow(session).to receive(:loaded?).and_return(true)

        warden_authenticate_returns admin
        env[API::Helpers::SUDO_HEADER] = user.username
      end

      it 'raises an error' do
        expect { current_user }.to raise_error(/Must be authenticated using an OAuth or personal access token to use sudo/)
      end
    end
  end
end
