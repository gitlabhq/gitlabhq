# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::StepUpAuthentication, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:ommiauth_provider_config) do
    GitlabSettings::Options.new(
      name: "openid_connect",
      step_up_auth: {
        admin_mode: {
          id_token: {
            required: required_id_token_claims,
            included: included_id_token_claims
          }
        }
      }
    )
  end

  let(:required_id_token_claims) { nil }
  let(:included_id_token_claims) { nil }

  let(:auth_hash_openid_connect) do
    OmniAuth::AuthHash.new({
      provider: 'openid_connect',
      info: {
        name: 'mockuser',
        email: 'mockuser@example.com',
        image: 'mock_user_thumbnail_url'
      },
      extra: {
        raw_info: {
          info: {
            name: 'mockuser',
            email: 'mockuser@example.com',
            image: 'mock_user_thumbnail_url'
          },
          **auth_hash_openid_connect_extra_raw_info
        }
      }
    })
  end

  let(:auth_hash_openid_connect_extra_raw_info) { {} }

  describe '.config_exists?' do
    let(:auth_hash_other_provider) { OmniAuth::AuthHash.new({ provider: 'other_provider' }) }

    subject { described_class.enabled_for_provider?(provider_name: oauth_auth_hash.provider, scope: scope) }

    before do
      stub_omniauth_setting(enabled: true, providers: [ommiauth_provider_config])
    end

    where(:required_id_token_claims, :included_id_token_claims, :oauth_auth_hash, :scope, :expected_result) do
      { claim_1: 'gold' } | nil                 | ref(:auth_hash_openid_connect) | :admin_mode        | true
      { claim_1: 'gold' } | nil                 | ref(:auth_hash_openid_connect) | :unsupported_scope | false

      { claim_1: 'gold' } | { claim_1: 'gold' } | ref(:auth_hash_openid_connect) | :admin_mode        | true
      { claim_1: 'gold' } | { claim_1: 'gold' } | ref(:auth_hash_openid_connect) | :unsupported_scope | false
      nil                 | { claim_1: 'gold' } | ref(:auth_hash_openid_connect) | :admin_mode        | true
      nil                 | { claim_1: 'gold' } | ref(:auth_hash_openid_connect) | :unsupported_scope | false

      {}                  | {}                  | ref(:auth_hash_openid_connect) | :admin_mode        | false
      {}                  | {}                  | ref(:auth_hash_openid_connect) | 'admin_mode'       | false
      {}                  | {}                  | ref(:auth_hash_openid_connect) | nil                | false
      {}                  | {}                  | ref(:auth_hash_other_provider) | :admin_mode        | false
      nil                 | nil                 | ref(:auth_hash_openid_connect) | :admin_mode        | false
    end

    with_them do
      it { is_expected.to eq expected_result }
    end
  end

  describe '.conditions_fulfilled?' do
    subject do
      described_class.conditions_fulfilled?(
        oauth_extra_metadata: auth_hash_openid_connect_extra_raw_info,
        provider: 'openid_connect',
        scope: :admin_mode
      )
    end

    before do
      stub_omniauth_setting(enabled: true, providers: [ommiauth_provider_config])
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting to ensure one-line table syntax
    where(:required_id_token_claims, :included_id_token_claims, :auth_hash_openid_connect_extra_raw_info, :expected_result) do
      { 'claim_1' => 'gold' }                     | nil                                                      | { claim_1: 'gold' }                                            | true
      { claim_1: 'gold' }                         | nil                                                      | { 'claim_1' => 'gold' }                                        | true
      { claim_1: 'gold' }                         | nil                                                      | { claim_1: 'gold' }                                            | true
      { claim_1: 'gold' }                         | nil                                                      | { claim_1: 'gold', claim_3: 'other_value' }                    | true
      { claim_1: 'gold' }                         | nil                                                      | { claim_1: 'silver' }                                          | false
      { claim_1: 'gold' }                         | nil                                                      | { claim_1: ['gold'] }                                          | false
      { claim_1: 'gold' }                         | nil                                                      | { claim_1: nil }                                               | false
      { claim_1: 'gold' }                         | nil                                                      | { claim_3: 'other_value' }                                     | false
      { claim_1: 'gold' }                         | nil                                                      | {}                                                             | false
      { claim_1: 'gold', claim_3: 'other_value' } | nil                                                      | { claim_1: 'gold' }                                            | false
      { claim_1: 'gold', claim_3: 'other_value' } | nil                                                      | { claim_1: 'gold', claim_3: 'other_value' }                    | true
      { claim_1: ['gold'] }                       | nil                                                      | { claim_1: 'gold' }                                            | false
      { claim_1: ['gold'] }                       | nil                                                      | { claim_1: ['gold'] }                                          | true

      nil                                         | { claim_2: [1, 2, 3] }                                   | { claim_2: 1 }                                                 | true
      nil                                         | { claim_2: [1, 2, 3] }                                   | { claim_2: 2 }                                                 | true
      nil                                         | { claim_2: 'mfa' }                                       | { claim_2: 'mfa' }                                             | true
      nil                                         | { claim_2: %w[mfa fpt] }                                 | { claim_2: 'fpt' }                                             | true
      nil                                         | { claim_2: %w[mfa fpt] }                                 | { claim_2: 'other_amr' }                                       | false
      nil                                         | { claim_2: %w[mfa fpt] }                                 | { claim_2: 'mfa', claim_3: 'other_value' }                     | true
      nil                                         | { claim_2: %w[gold silver], claim_3: %w[bronze copper] } | { claim_2: 'silver' }                                          | false
      nil                                         | { claim_2: %w[gold silver], claim_3: %w[bronze copper] } | { claim_2: 'silver', claim_3: 'copper' }                       | true

      { claim_1: 'gold' }                         | { claim_1: 'gold' }                                      | { claim_1: 'gold' }                                            | true
      { claim_1: 'gold' }                         | { claim_1: ['gold'] }                                    | { claim_1: 'gold' }                                            | true
      { claim_1: 'gold' }                         | { claim_1: %w[gold silver] }                             | { claim_1: 'gold' }                                            | true
      { claim_1: 'gold' }                         | { claim_1: %w[gold silver] }                             | { claim_1: 'silver' }                                          | false
      { claim_1: 'gold' }                         | { claim_2: %w[mfa fpt] }                                 | { claim_1: 'gold', claim_2: 'mfa' }                            | true
      { claim_1: 'gold' }                         | { claim_2: %w[mfa fpt] }                                 | { claim_1: 'silver', claim_2: 'mfa' }                          | false
      { claim_1: 'gold' }                         | { claim_2: %w[mfa fpt] }                                 | { claim_1: 'gold', claim_2: 'other_amr' }                      | false
      { claim_1: 'gold' }                         | { claim_2: %w[mfa fpt] }                                 | { claim_1: 'silver', claim_2: 'other_amr' }                    | false
      { claim_1: 'gold', claim_3: 'other_value' } | { claim_2: %w[gold silver], claim_3: %w[bronze copper] } | { claim_1: 'gold', claim_2: 'silver', claim_3: 'other_value' } | false
      { claim_1: 'gold', claim_3: 'other_value' } | { claim_2: %w[gold silver], claim_3: %w[bronze copper] } | { claim_1: 'gold', claim_2: 'silver', claim_3: 'copper' }      | false
      { claim_1: 'gold', claim_3: 'other_value' } | { claim_2: %w[gold silver], claim_3: %w[bronze copper] } | { claim_1: 'gold', claim_2: 'silver', claim_3: 'platinium' }   | false

      {}                                          | {}                                                       | { claim_1: 'gold' }                                            | false
      {}                                          | nil                                                      | { claim_1: 'gold' }                                            | false
      nil                                         | {}                                                       | { claim_1: 'gold' }                                            | false
      nil                                         | nil                                                      | { claim_1: 'gold' }                                            | false
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it { is_expected.to eq expected_result }
    end
  end

  describe '.succeeded?' do
    let(:required_id_token_claims) { { claim_1: 'gold' } }

    let(:session) { { 'omniauth_step_up_auth' => step_up_auth_session } }

    subject { described_class.succeeded?(session) }

    before do
      stub_omniauth_setting(enabled: true, providers: [ommiauth_provider_config])
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting to ensure one-line table syntax
    where(:step_up_auth_session, :expected_result) do
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'succeeded' } } } }                                                                     | true
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } } } }                                                                        | false
      lazy { { 'other_provider' => { 'admin_mode' => { 'state' => 'succeeded' } } } }                                                                     | false
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'succeeded' } }, 'other_provider' => { 'admin_mode' => { 'state' => 'failed' } } } }    | true
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'succeeded' } }, 'other_provider' => { 'admin_mode' => { 'state' => 'succeeded' } } } } | true
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } },    'other_provider' => { 'admin_mode' => { 'state' => 'failed' } } } }    | false
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } },    'other_provider' => { 'admin_mode' => { 'state' => 'succeeded' } } } } | false
      lazy { { 'openid_connect' => { 'other_mode' => { 'state' => 'succeeded' } }, 'other_provider' => { 'admin_mode' => { 'state' => 'failed' } } } }    | false

      nil                                                                                                                                                 | false
      {}                                                                                                                                                  | false
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it { is_expected.to eq expected_result }
    end
  end

  describe '.disable_step_up_authentication!' do
    let(:required_id_token_claims) { { claim_1: 'gold' } }
    let(:scope) { :admin_mode }
    let(:session) do
      {
        'omniauth_step_up_auth' => {
          'openid_connect' => {
            'admin_mode' => { 'state' => 'succeeded' },
            'other_scope' => { 'state' => 'succeeded' }
          },
          'other_provider' => {
            'admin_mode' => { 'state' => 'failed' }
          }
        }
      }
    end

    subject(:disable_step_up_authentication!) do
      described_class.disable_step_up_authentication!(session: session, scope: scope)
      session
    end

    before do
      stub_omniauth_setting(enabled: true, providers: [ommiauth_provider_config])
    end

    it 'removes the step-up auth data for the given scope from all providers' do
      disable_step_up_authentication!

      expect(session['omniauth_step_up_auth']['openid_connect']).not_to have_key('admin_mode')
      expect(session['omniauth_step_up_auth']['openid_connect']).to have_key('other_scope')
      expect(session['omniauth_step_up_auth']['other_provider']).not_to have_key('admin_mode')

      expect(described_class.succeeded?(session)).to be_falsey
    end

    context 'when session is empty' do
      let(:session) { {} }

      it { is_expected.to eq({}) }
    end

    context 'when scope does not exist' do
      let(:scope) { :nonexistent_scope }

      it 'does not change the session' do
        disable_step_up_authentication!

        expect(session['omniauth_step_up_auth']['openid_connect']).to have_key('admin_mode')
        expect(session['omniauth_step_up_auth']['openid_connect']).to have_key('other_scope')
        expect(session['omniauth_step_up_auth']['other_provider']).to have_key('admin_mode')
      end
    end
  end
end
