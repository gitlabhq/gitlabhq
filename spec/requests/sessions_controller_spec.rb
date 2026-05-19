# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, type: :request, feature_category: :system_access do
  include Authn::WebauthnSpecHelpers
  include SessionHelpers

  describe '#destroy' do
    let_it_be(:user) { create(:user) }
    let(:expected_context) do
      { 'meta.caller_id' => 'SessionsController#destroy',
        'meta.user' => user.username }
    end

    subject(:perform_request) do
      sign_in(user)
      post destroy_user_session_path
    end

    include_examples 'set_current_context'
  end

  describe '#new' do
    let(:expected_context) do
      { 'meta.caller_id' => 'SessionsController#new' }
    end

    subject(:perform_request) do
      get new_user_session_path
    end

    it 'pushes twoStepSignIn feature flag to frontend' do
      perform_request

      expect(response.body).to have_pushed_frontend_feature_flags(twoStepSignIn: false)
    end

    include_examples 'set_current_context'
  end

  describe '#create' do
    let_it_be(:user) { create(:user) }
    let(:expected_context) do
      { 'meta.caller_id' => 'SessionsController#create',
        'meta.user' => user.username }
    end

    subject(:perform_request) do
      user.update!(failed_attempts: User.maximum_attempts.pred)
      post user_session_path, params: { user: { login: user.username, password: user.password.succ } }
    end

    include_examples 'set_current_context'
  end

  describe '#new_passkey' do
    shared_examples 'does not call handle_passwordless_flow' do
      it 'does not call handle_passwordless_flow' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).not_to receive(:handle_passwordless_flow)
        end

        perform_request
      end

      it 'responds with status 403' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    shared_examples 'calls handle_passwordless_flow' do
      it 'calls handle_passwordless_flow' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:handle_passwordless_flow)
        end

        perform_request
      end
    end

    def perform_request(params: {})
      post users_passkeys_sign_in_path, params: params
    end

    it_behaves_like 'calls handle_passwordless_flow'

    context 'when password authentication for web is disabled' do
      before do
        stub_application_setting(password_authentication_enabled_for_web: false)
      end

      it_behaves_like 'does not call handle_passwordless_flow'
    end

    context 'for passkey authentication', :clean_gitlab_redis_sessions do
      let_it_be(:user) { create(:user) }
      let_it_be(:passkey) { create_passkey(user) }

      let(:device_response) { device_response_after_authentication(user, passkey) }
      let(:params) { { device_response: device_response } }

      before do
        stub_session(session_data: { challenge: challenge })
      end

      it 'authenticates the user', :aggregate_failures do
        perform_request(params: params)

        expect(response).to redirect_to(root_path)
        expect(request.env['warden']).to be_authenticated
        expect(request.env['warden'].user).to eq user
      end

      context 'when passkey authentication is disabled for user' do
        before do
          allow_next_found_instance_of(User) do |instance|
            allow(instance).to receive(:allow_passkey_authentication?).and_return(false)
          end
        end

        it 'does not authenticate the user', :aggregate_failures do
          perform_request(params: params)

          expect(request.env['warden']).not_to be_authenticated
          expect(request.env['warden'].user).to be_nil
        end

        it 'returns generic error message' do
          perform_request(params: params)

          expect(flash[:alert]).to eq(_('Failed to connect to your device. Try again.'))
        end
      end
    end
  end

  # FF cleanup: self_managed_welcome_onboarding
  describe 'POST /users/sign_in (self_managed_welcome_onboarding redirect)', feature_category: :onboarding do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:regular_user) { create(:user) }

    def sign_in_as(user)
      post user_session_path, params: { user: { login: user.username, password: user.password } }
    end

    context 'when :self_managed_welcome_onboarding flag is enabled' do
      context 'with an admin user and no groups (fresh install)' do
        before do
          stub_application_setting(admin_mode: false)
          allow(Group).to receive(:exists?).and_return(false)
        end

        it 'redirects to new_admin_registrations_group_path' do
          sign_in_as(admin)

          expect(response).to redirect_to(new_admin_registrations_group_path)
        end
      end

      context 'with an admin user when groups exist (upgrade scenario)' do
        before do
          allow(Group).to receive(:exists?).and_return(true)
        end

        it 'does not return the create first project path' do
          sign_in_as(admin)

          expect(response).to redirect_to(root_path)
        end
      end

      context 'with a non-admin user' do
        before do
          allow(Group).to receive(:exists?).and_return(false)
        end

        it 'redirects to root path' do
          sign_in_as(regular_user)

          expect(response).to redirect_to(root_path)
        end
      end
    end

    context 'when on a Dedicated instance' do
      before do
        stub_application_setting(gitlab_dedicated_instance: true)
        stub_application_setting(admin_mode: false)
        allow(Group).to receive(:exists?).and_return(false)
      end

      it 'redirects to root path' do
        sign_in_as(admin)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when :self_managed_welcome_onboarding flag is disabled' do
      before do
        stub_feature_flags(self_managed_welcome_onboarding: false)
        allow(Group).to receive(:exists?).and_return(false)
      end

      it 'redirects to root path' do
        sign_in_as(admin)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'private methods' do
    context 'with .passwordless_passkey_params' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:render).with('devise/sessions/passkeys')
        end
      end

      context 'when parameter sanitization is applied' do
        let(:params) do
          {
            device_response: 'valid_response',
            remember_me: '1',
            admin: true,
            require_two_factor_authentication: false
          }
        end

        let(:sanitized_params) { controller.send(:passwordless_passkey_params) }

        it 'returns a hash of only permitted scalar keys' do
          post users_passkeys_sign_in_path, params: params

          expect(sanitized_params.to_h).to include({
            device_response: 'valid_response',
            remember_me: '1'
          })

          expect(sanitized_params.to_h).not_to include({
            admin: true,
            require_two_factor_authentication: false
          })
        end
      end
    end

    context 'with .user_params' do
      context 'when parameter sanitization is applied' do
        let(:params) do
          {
            user: {
              login: 'john_doe@gmail.com ',
              password: 'password123',
              device_response: 'valid_response',
              remember_me: '1',
              admin: true,
              require_two_factor_authentication_from_group: false
            }
          }
        end

        let(:sanitized_params) { controller.send(:user_params) }

        it 'returns a hash of only permitted scalar keys, with a stripped login' do
          post user_session_path, params: params

          expect(sanitized_params.to_h).to include({
            login: 'john_doe@gmail.com',
            device_response: 'valid_response',
            remember_me: '1'
          })

          expect(sanitized_params.to_h).not_to include({
            admin: true,
            require_two_factor_authentication_from_group: false
          })
        end
      end
    end
  end
end
