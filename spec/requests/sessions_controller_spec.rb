# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, type: :request, feature_category: :system_access do
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
    end

    shared_examples 'calls handle_passwordless_flow' do
      it 'calls handle_passwordless_flow' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:handle_passwordless_flow)
        end

        perform_request
      end
    end

    def perform_request
      post users_passkeys_sign_in_path
    end

    context 'when :passkeys feature flag is off' do
      before do
        stub_feature_flags(passkeys: false)
      end

      it_behaves_like 'does not call handle_passwordless_flow'
    end

    context 'when :passkeys feature flag is on' do
      it_behaves_like 'calls handle_passwordless_flow'
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
