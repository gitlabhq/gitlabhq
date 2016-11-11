require 'spec_helper'

describe API::Helpers, api: true do
  include API::Helpers
  include ApiHelpers
  include SentryHelper

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:key) { create(:key, user: user) }

  let(:params) { {} }
  let(:env) { { 'REQUEST_METHOD' => 'GET' } }
  let(:request) { Rack::Request.new(env) }

  def set_env(token_usr, identifier)
    clear_env
    clear_param
    env[API::Helpers::PRIVATE_TOKEN_HEADER] = token_usr.private_token
    env[API::Helpers::SUDO_HEADER] = identifier
  end

  def set_param(token_usr, identifier)
    clear_env
    clear_param
    params[API::Helpers::PRIVATE_TOKEN_PARAM] = token_usr.private_token
    params[API::Helpers::SUDO_PARAM] = identifier
  end

  def clear_env
    env.delete(API::Helpers::PRIVATE_TOKEN_HEADER)
    env.delete(API::Helpers::SUDO_HEADER)
  end

  def clear_param
    params.delete(API::Helpers::PRIVATE_TOKEN_PARAM)
    params.delete(API::Helpers::SUDO_PARAM)
  end

  def warden_authenticate_returns(value)
    warden = double("warden", authenticate: value)
    env['warden'] = warden
  end

  def doorkeeper_guard_returns(value)
    allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ value }
  end

  def error!(message, status)
    raise Exception
  end

  describe ".current_user" do
    subject { current_user }

    describe "Warden authentication" do
      before { doorkeeper_guard_returns false }

      context "with invalid credentials" do
        context "GET request" do
          before { env['REQUEST_METHOD'] = 'GET' }
          it { is_expected.to be_nil }
        end
      end

      context "with valid credentials" do
        before { warden_authenticate_returns user }

        context "GET request" do
          before { env['REQUEST_METHOD'] = 'GET' }
          it { is_expected.to eq(user) }
        end

        context "HEAD request" do
          before { env['REQUEST_METHOD'] = 'HEAD' }
          it { is_expected.to eq(user) }
        end

        context "PUT request" do
          before { env['REQUEST_METHOD'] = 'PUT' }
          it { is_expected.to be_nil }
        end

        context "POST request" do
          before { env['REQUEST_METHOD'] = 'POST' }
          it { is_expected.to be_nil }
        end

        context "DELETE request" do
          before { env['REQUEST_METHOD'] = 'DELETE' }
          it { is_expected.to be_nil }
        end
      end
    end

    describe "when authenticating using a user's private token" do
      it "returns nil for an invalid token" do
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = 'invalid token'
        allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ false }
        expect(current_user).to be_nil
      end

      it "returns nil for a user without access" do
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = user.private_token
        allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(false)
        expect(current_user).to be_nil
      end

      it "leaves user as is when sudo not specified" do
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = user.private_token
        expect(current_user).to eq(user)
        clear_env
        params[API::Helpers::PRIVATE_TOKEN_PARAM] = user.private_token
        expect(current_user).to eq(user)
      end
    end

    describe "when authenticating using a user's personal access tokens" do
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      it "returns nil for an invalid token" do
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = 'invalid token'
        allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ false }
        expect(current_user).to be_nil
      end

      it "returns nil for a user without access" do
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(false)
        expect(current_user).to be_nil
      end

      it "leaves user as is when sudo not specified" do
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        expect(current_user).to eq(user)
        clear_env
        params[API::Helpers::PRIVATE_TOKEN_PARAM] = personal_access_token.token
        expect(current_user).to eq(user)
      end

      it 'does not allow revoked tokens' do
        personal_access_token.revoke!
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ false }
        expect(current_user).to be_nil
      end

      it 'does not allow expired tokens' do
        personal_access_token.update_attributes!(expires_at: 1.day.ago)
        env[API::Helpers::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        allow_any_instance_of(self.class).to receive(:doorkeeper_guard){ false }
        expect(current_user).to be_nil
      end
    end

    it "changes current user to sudo when admin" do
      set_env(admin, user.id)
      expect(current_user).to eq(user)
      set_param(admin, user.id)
      expect(current_user).to eq(user)
      set_env(admin, user.username)
      expect(current_user).to eq(user)
      set_param(admin, user.username)
      expect(current_user).to eq(user)
    end

    it "throws an error when the current user is not an admin and attempting to sudo" do
      set_env(user, admin.id)
      expect { current_user }.to raise_error(Exception)
      set_param(user, admin.id)
      expect { current_user }.to raise_error(Exception)
      set_env(user, admin.username)
      expect { current_user }.to raise_error(Exception)
      set_param(user, admin.username)
      expect { current_user }.to raise_error(Exception)
    end

    it "throws an error when the user cannot be found for a given id" do
      id = user.id + admin.id
      expect(user.id).not_to eq(id)
      expect(admin.id).not_to eq(id)
      set_env(admin, id)
      expect { current_user }.to raise_error(Exception)

      set_param(admin, id)
      expect { current_user }.to raise_error(Exception)
    end

    it "throws an error when the user cannot be found for a given username" do
      username = "#{user.username}#{admin.username}"
      expect(user.username).not_to eq(username)
      expect(admin.username).not_to eq(username)
      set_env(admin, username)
      expect { current_user }.to raise_error(Exception)

      set_param(admin, username)
      expect { current_user }.to raise_error(Exception)
    end

    it "handles sudo's to oneself" do
      set_env(admin, admin.id)
      expect(current_user).to eq(admin)
      set_param(admin, admin.id)
      expect(current_user).to eq(admin)
      set_env(admin, admin.username)
      expect(current_user).to eq(admin)
      set_param(admin, admin.username)
      expect(current_user).to eq(admin)
    end

    it "handles multiple sudo's to oneself" do
      set_env(admin, user.id)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
      set_env(admin, user.username)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)

      set_param(admin, user.id)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
      set_param(admin, user.username)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
    end

    it "handles multiple sudo's to oneself using string ids" do
      set_env(admin, user.id.to_s)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)

      set_param(admin, user.id.to_s)
      expect(current_user).to eq(user)
      expect(current_user).to eq(user)
    end
  end

  describe '.sudo_identifier' do
    it "returns integers when input is an int" do
      set_env(admin, '123')
      expect(sudo_identifier).to eq(123)
      set_env(admin, '0001234567890')
      expect(sudo_identifier).to eq(1234567890)

      set_param(admin, '123')
      expect(sudo_identifier).to eq(123)
      set_param(admin, '0001234567890')
      expect(sudo_identifier).to eq(1234567890)
    end

    it "returns string when input is an is not an int" do
      set_env(admin, '12.30')
      expect(sudo_identifier).to eq("12.30")
      set_env(admin, 'hello')
      expect(sudo_identifier).to eq('hello')
      set_env(admin, ' 123')
      expect(sudo_identifier).to eq(' 123')

      set_param(admin, '12.30')
      expect(sudo_identifier).to eq("12.30")
      set_param(admin, 'hello')
      expect(sudo_identifier).to eq('hello')
      set_param(admin, ' 123')
      expect(sudo_identifier).to eq(' 123')
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
end
