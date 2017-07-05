require 'spec_helper'

describe API::Helpers do
  include API::APIGuard::HelperMethods
  include described_class
  include SentryHelper

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }

  let(:params) { {} }
  let(:env) { { 'REQUEST_METHOD' => 'GET' } }
  let(:request) { Rack::Request.new(env) }
  let(:header) { }

  before do
    allow_any_instance_of(self.class).to receive(:options).and_return({})
  end

  def set_env(user_or_token, identifier)
    clear_env
    clear_param
    env[API::APIGuard::PRIVATE_TOKEN_HEADER] = user_or_token.respond_to?(:private_token) ? user_or_token.private_token : user_or_token
    env[API::Helpers::SUDO_HEADER] = identifier.to_s
  end

  def set_param(user_or_token, identifier)
    clear_env
    clear_param
    params[API::APIGuard::PRIVATE_TOKEN_PARAM] = user_or_token.respond_to?(:private_token) ? user_or_token.private_token : user_or_token
    params[API::Helpers::SUDO_PARAM] = identifier.to_s
  end

  def clear_env
    env.delete(API::APIGuard::PRIVATE_TOKEN_HEADER)
    env.delete(API::Helpers::SUDO_HEADER)
  end

  def clear_param
    params.delete(API::APIGuard::PRIVATE_TOKEN_PARAM)
    params.delete(API::Helpers::SUDO_PARAM)
  end

  def warden_authenticate_returns(value)
    warden = double("warden", authenticate: value)
    env['warden'] = warden
  end

  def doorkeeper_guard_returns(value)
    allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ value }
  end

  def error!(message, status, header)
    raise Exception.new("#{status} - #{message}")
  end

  describe ".current_user" do
    subject { current_user }

    describe "Warden authentication" do
      before do
        doorkeeper_guard_returns false
      end

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
        end

        context "HEAD request" do
          before do
            env['REQUEST_METHOD'] = 'HEAD'
          end

          it { is_expected.to eq(user) }
        end

        context "PUT request" do
          before do
            env['REQUEST_METHOD'] = 'PUT'
          end

          it { is_expected.to be_nil }
        end

        context "POST request" do
          before do
            env['REQUEST_METHOD'] = 'POST'
          end

          it { is_expected.to be_nil }
        end

        context "DELETE request" do
          before do
            env['REQUEST_METHOD'] = 'DELETE'
          end

          it { is_expected.to be_nil }
        end
      end
    end

    describe "when authenticating using a user's private token" do
      it "returns nil for an invalid token" do
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = 'invalid token'
        allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ false }

        expect(current_user).to be_nil
      end

      it "returns nil for a user without access" do
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = user.private_token
        allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(false)

        expect(current_user).to be_nil
      end

      it "leaves user as is when sudo not specified" do
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = user.private_token

        expect(current_user).to eq(user)

        clear_env

        params[API::APIGuard::PRIVATE_TOKEN_PARAM] = user.private_token

        expect(current_user).to eq(user)
      end
    end

    describe "when authenticating using a user's personal access tokens" do
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      before do
        allow_any_instance_of(self.class).to receive(:doorkeeper_guard) { false }
      end

      it "returns nil for an invalid token" do
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = 'invalid token'

        expect(current_user).to be_nil
      end

      it "returns nil for a user without access" do
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(false)

        expect(current_user).to be_nil
      end

      it "returns nil for a token without the appropriate scope" do
        personal_access_token = create(:personal_access_token, user: user, scopes: ['read_user'])
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect(current_user).to be_nil
      end

      it "leaves user as is when sudo not specified" do
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        expect(current_user).to eq(user)
        clear_env
        params[API::APIGuard::PRIVATE_TOKEN_PARAM] = personal_access_token.token

        expect(current_user).to eq(user)
      end

      it 'does not allow revoked tokens' do
        personal_access_token.revoke!
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect(current_user).to be_nil
      end

      it 'does not allow expired tokens' do
        personal_access_token.update_attributes!(expires_at: 1.day.ago)
        env[API::APIGuard::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect(current_user).to be_nil
      end
    end

    context 'sudo usage' do
      context 'with admin' do
        context 'with header' do
          context 'with id' do
            it 'changes current_user to sudo' do
              set_env(admin, user.id)

              expect(current_user).to eq(user)
            end

            it 'memoize the current_user: sudo permissions are not run against the sudoed user' do
              set_env(admin, user.id)

              expect(current_user).to eq(user)
              expect(current_user).to eq(user)
            end

            it 'handles sudo to oneself' do
              set_env(admin, admin.id)

              expect(current_user).to eq(admin)
            end

            it 'throws an error when user cannot be found' do
              id = user.id + admin.id
              expect(user.id).not_to eq(id)
              expect(admin.id).not_to eq(id)

              set_env(admin, id)

              expect { current_user }.to raise_error(Exception)
            end
          end

          context 'with username' do
            it 'changes current_user to sudo' do
              set_env(admin, user.username)

              expect(current_user).to eq(user)
            end

            it 'handles sudo to oneself' do
              set_env(admin, admin.username)

              expect(current_user).to eq(admin)
            end

            it "throws an error when the user cannot be found for a given username" do
              username = "#{user.username}#{admin.username}"
              expect(user.username).not_to eq(username)
              expect(admin.username).not_to eq(username)

              set_env(admin, username)

              expect { current_user }.to raise_error(Exception)
            end
          end
        end

        context 'with param' do
          context 'with id' do
            it 'changes current_user to sudo' do
              set_param(admin, user.id)

              expect(current_user).to eq(user)
            end

            it 'handles sudo to oneself' do
              set_param(admin, admin.id)

              expect(current_user).to eq(admin)
            end

            it 'handles sudo to oneself using string' do
              set_env(admin, user.id.to_s)

              expect(current_user).to eq(user)
            end

            it 'throws an error when user cannot be found' do
              id = user.id + admin.id
              expect(user.id).not_to eq(id)
              expect(admin.id).not_to eq(id)

              set_param(admin, id)

              expect { current_user }.to raise_error(Exception)
            end
          end

          context 'with username' do
            it 'changes current_user to sudo' do
              set_param(admin, user.username)

              expect(current_user).to eq(user)
            end

            it 'handles sudo to oneself' do
              set_param(admin, admin.username)

              expect(current_user).to eq(admin)
            end

            it "throws an error when the user cannot be found for a given username" do
              username = "#{user.username}#{admin.username}"
              expect(user.username).not_to eq(username)
              expect(admin.username).not_to eq(username)

              set_param(admin, username)

              expect { current_user }.to raise_error(Exception)
            end
          end
        end
      end

      context 'with regular user' do
        context 'with env' do
          it 'changes current_user to sudo when admin and user id' do
            set_env(user, admin.id)

            expect { current_user }.to raise_error(Exception)
          end

          it 'changes current_user to sudo when admin and user username' do
            set_env(user, admin.username)

            expect { current_user }.to raise_error(Exception)
          end
        end

        context 'with params' do
          it 'changes current_user to sudo when admin and user id' do
            set_param(user, admin.id)

            expect { current_user }.to raise_error(Exception)
          end

          it 'changes current_user to sudo when admin and user username' do
            set_param(user, admin.username)

            expect { current_user }.to raise_error(Exception)
          end
        end
      end
    end
  end

  describe '.sudo?' do
    context 'when no sudo env or param is passed' do
      before do
        doorkeeper_guard_returns(nil)
      end

      it 'returns false' do
        expect(sudo?).to be_falsy
      end
    end

    context 'when sudo env or param is passed', 'user is not an admin' do
      before do
        set_env(user, '123')
      end

      it 'returns an 403 Forbidden' do
        expect { sudo? }.to raise_error '403 - {"message"=>"403 Forbidden  - Must be admin to use sudo"}'
      end
    end

    context 'when sudo env or param is passed', 'user is admin' do
      context 'personal access token is used' do
        before do
          personal_access_token = create(:personal_access_token, user: admin)
          set_env(personal_access_token.token, user.id)
        end

        it 'returns an 403 Forbidden' do
          expect { sudo? }.to raise_error '403 - {"message"=>"403 Forbidden  - Private token must be specified in order to use sudo"}'
        end
      end

      context 'private access token is used' do
        before do
          set_env(admin.private_token, user.id)
        end

        it 'returns true' do
          expect(sudo?).to be_truthy
        end
      end
    end
  end

  describe '.handle_api_exception' do
    before do
      allow_any_instance_of(self.class).to receive(:sentry_enabled?).and_return(true)
      allow_any_instance_of(self.class).to receive(:rack_response)
    end

    it 'does not report a MethodNotAllowed exception to Sentry' do
      exception = Grape::Exceptions::MethodNotAllowed.new({ 'X-GitLab-Test' => '1' })
      allow(exception).to receive(:backtrace).and_return(caller)

      expect(Raven).not_to receive(:capture_exception).with(exception)

      handle_api_exception(exception)
    end

    it 'does report RuntimeError to Sentry' do
      exception = RuntimeError.new('test error')
      allow(exception).to receive(:backtrace).and_return(caller)

      expect_any_instance_of(self.class).to receive(:sentry_context)
      expect(Raven).to receive(:capture_exception).with(exception)

      handle_api_exception(exception)
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
        allow_any_instance_of(self.class).to receive(:initial_current_user).and_return(nil)
      end

      it 'returns a 401 response' do
        expect { authenticate! }.to raise_error '401 - {"message"=>"401 Unauthorized"}'
      end
    end

    context 'current_user is present' do
      let(:user) { build(:user) }

      before do
        expect_any_instance_of(self.class).to receive(:current_user).at_least(:once).and_return(user)
        expect_any_instance_of(self.class).to receive(:initial_current_user).and_return(user)
      end

      it 'does not raise an error' do
        expect { authenticate! }.not_to raise_error
      end
    end

    context 'current_user is blocked' do
      let(:user) { build(:user, :blocked) }

      before do
        expect_any_instance_of(self.class).to receive(:current_user).at_least(:once).and_return(user)
      end

      it 'raises an error' do
        expect_any_instance_of(self.class).to receive(:initial_current_user).and_return(user)

        expect { authenticate! }.to raise_error '401 - {"message"=>"401 Unauthorized"}'
      end

      it "doesn't raise an error if an admin user is impersonating a blocked user (via sudo)" do
        admin_user = build(:user, :admin)

        expect_any_instance_of(self.class).to receive(:initial_current_user).and_return(admin_user)

        expect { authenticate! }.not_to raise_error
      end
    end
  end
end
