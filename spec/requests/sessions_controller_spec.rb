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

    it 'pushes passkeys feature flag to frontend' do
      perform_request

      expect(response.body).to have_pushed_frontend_feature_flags(passkeys: true)
    end

    it 'pushes signInFormVue feature flag to frontend' do
      perform_request

      expect(response.body).to have_pushed_frontend_feature_flags(signInFormVue: true)
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

    context 'when :passkeys feature flag is off' do
      before do
        stub_feature_flags(passkeys: false)
      end

      it_behaves_like 'does not call handle_passwordless_flow'
    end

    context 'when :passkeys feature flag is on' do
      it_behaves_like 'calls handle_passwordless_flow'

      context 'when password authentication for web is disabled' do
        before do
          stub_application_setting(password_authentication_enabled_for_web: false)
        end

        it_behaves_like 'does not call handle_passwordless_flow'
      end
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
  end
end
