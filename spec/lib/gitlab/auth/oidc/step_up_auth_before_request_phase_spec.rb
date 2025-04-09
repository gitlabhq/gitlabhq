# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::StepUpAuthBeforeRequestPhase, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:env) do
    {
      'omniauth.strategy' => class_double(OmniAuth::Strategies, name: provider),
      'rack.request.query_hash' => { 'step_up_auth_scope' => step_up_auth_scope },
      'rack.session' => session,
      'warden' => instance_double(Warden::Proxy, user: build_stubbed(:user))
    }
  end

  let(:session) { {} }
  let(:session_with_step_up_state_requested) do
    { 'omniauth_step_up_auth' => { 'openid_connect' => { 'admin_mode' => { 'state' => 'requested' } } } }
  end

  let(:provider_step_up_auth_name) { provider_step_up_auth.name }
  let(:provider_step_up_auth) do
    GitlabSettings::Options.new(
      name: 'openid_connect',
      step_up_auth: {
        admin_mode: {
          id_token: {
            required: {
              acr: 'gold'
            }
          }
        }
      }
    )
  end

  before do
    stub_omniauth_setting(enabled: true, providers: [provider_step_up_auth])
  end

  describe '.call' do
    subject(:call_middleware) { described_class.call(env) }

    # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
    where(:provider, :step_up_auth_scope, :session, :expected_session) do
      ref(:provider_step_up_auth_name) | 'admin_mode'  | {}                                                                                                    | ref(:session_with_step_up_state_requested)
      ref(:provider_step_up_auth_name) | 'admin_mode'  | ref(:session_with_step_up_state_requested)                                                            | ref(:session_with_step_up_state_requested)
      ref(:provider_step_up_auth_name) | 'admin_mode'  | { 'omniauth_step_up_auth' => { 'other_provider' => { 'admin_mode' => { 'state' => 'requested' } } } } | lazy { session.deep_merge(session_with_step_up_state_requested) }
      ref(:provider_step_up_auth_name) | 'admin_mode'  | { 'other_session_key' => 'other_session_value' }                                                      | lazy { session.deep_merge(session_with_step_up_state_requested) }
      ref(:provider_step_up_auth_name) | 'other_scope' | {}                                                                                                    | {}
      ref(:provider_step_up_auth_name) | 'other_scope' | ref(:session_with_step_up_state_requested)                                                            | ref(:session_with_step_up_state_requested)
      ref(:provider_step_up_auth_name) | ''            | {}                                                                                                    | {}
      ref(:provider_step_up_auth_name) | nil           | {}                                                                                                    | {}
      'other_provider'                 | 'admin_mode'  | {}                                                                                                    | {}
      nil                              | 'admin_mode'  | {}                                                                                                    | {}
      nil                              | nil           | {}                                                                                                    | {}
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'sets the session state to requested' do
        call_middleware

        expect(session).to eq(expected_session)
      end

      context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
        end

        it 'does not modify the session' do
          expect { call_middleware }.not_to change { session }
        end
      end
    end

    context 'when user is not authenticated' do
      let(:env) { super().merge('warden' => instance_double(Warden::Proxy, user: nil)) }
      let(:provider) { provider_step_up_auth_name }
      let(:step_up_auth_scope) { 'admin_mode' }

      it 'does not modify the session' do
        expect { call_middleware }.not_to change { session }
      end
    end

    context 'when warden is blank' do
      let(:env) { super().merge('warden' => nil) }
      let(:provider) { provider_step_up_auth_name }
      let(:step_up_auth_scope) { 'admin_mode' }

      it 'does not modify the session' do
        expect { call_middleware }.not_to change { session }
      end
    end
  end
end
