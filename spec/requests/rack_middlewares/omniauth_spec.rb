# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth Rack middlewares', feature_category: :system_access do
  include SessionHelpers

  describe 'OmniAuth before_request_phase callback' do
    it 'increments Prometheus counter' do
      expect { post('/users/auth/google_oauth2') }
        .to change {
          Gitlab::Metrics.registry.get(:gitlab_omniauth_login_total)
                                  &.get(omniauth_provider: 'google_oauth2', status: 'initiated')
                                  .to_f
        }.by(1)
    end
  end

  describe 'OmniAuth before_request_phase callback for step-up authentication' do
    let_it_be(:user) { create(:user) }

    let(:oauth_provider_config_with_step_up_auth) do
      GitlabSettings::Options.new(
        name: "openid_connect",
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

    let(:step_up_auth_scope) { 'admin_mode' }

    let(:expected_step_up_auth_session_hash) do
      { 'omniauth_step_up_auth' => { 'openid_connect' => { 'admin_mode' => { 'state' => 'requested' } } } }
    end

    subject(:response_session) do
      post("/users/auth/openid_connect?step_up_auth_scope=#{step_up_auth_scope}")
      session.to_h
    end

    before do
      stub_omniauth_setting(enabled: true, providers: [oauth_provider_config_with_step_up_auth])

      sign_in(user)
    end

    it { is_expected.to include(expected_step_up_auth_session_hash) }

    context 'with blank step_up_auth_scope param' do
      let(:step_up_auth_scope) { '' }

      it { is_expected.not_to include('omniauth_step_up_auth') }
    end

    context 'with invalid step_up_auth_scope param' do
      let(:step_up_auth_scope) { 'invalid_scope' }

      it { is_expected.not_to include('omniauth_step_up_auth') }
    end

    context 'without step_up_auth_scope param' do
      subject(:response_session) do
        post('/users/auth/openid_connect')
        session.to_h
      end

      it { is_expected.not_to include('omniauth_step_up_auth') }
    end

    context 'when session for omniauth_step_up_auth is available', :clean_gitlab_redis_sessions do
      before do
        stub_session(
          session_data: {
            'omniauth_step_up_auth' => { 'openid_connect' => { 'admin_mode' => { 'state' => 'requested' } } }
          },
          user_id: user.id
        )
      end

      it { is_expected.to include(expected_step_up_auth_session_hash) }
    end

    context 'when requesting step-up auth for unconfigured provider' do
      subject(:response_session) do
        post('/users/auth/auth0?step_up_auth_scope=admin_mode')
        session.to_h
      end

      it { is_expected.not_to include('omniauth_step_up_auth') }
    end
  end
end
