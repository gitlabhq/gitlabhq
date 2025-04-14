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
            required: required_id_token_claims
          }
        }
      }
    )
  end

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

    where(:required_id_token_claims, :oauth_auth_hash, :scope, :expected_result) do
      { claim_1: 'gold' } | ref(:auth_hash_openid_connect) | :admin_mode        | true
      { claim_1: 'gold' } | ref(:auth_hash_openid_connect) | :unsupported_scope | false
      {}                  | ref(:auth_hash_openid_connect) | :admin_mode        | false
      {}                  | ref(:auth_hash_openid_connect) | 'admin_mode'       | false
      {}                  | ref(:auth_hash_openid_connect) | nil                | false
      {}                  | ref(:auth_hash_other_provider) | :admin_mode        | false
      nil                 | ref(:auth_hash_openid_connect) | :admin_mode        | false
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

    # -- Avoid formatting to ensure one-line table syntax
    where(:required_id_token_claims, :auth_hash_openid_connect_extra_raw_info, :expected_result) do
      { claim_1: 'gold' }                         | { claim_1: 'gold' }                         | true
      { 'claim_1' => 'gold' }                     | { claim_1: 'gold' }                         | true
      { claim_1: 'gold' }                         | { 'claim_1' => 'gold' }                     | true
      { claim_1: 'gold' }                         | { claim_1: 'gold', claim_3: 'other_value' } | true
      { claim_1: 'gold' }                         | { claim_1: 'silver' }                       | false
      { claim_1: 'gold' }                         | { claim_1: ['gold'] }                       | false
      { claim_1: 'gold' }                         | { claim_1: nil }                            | false
      { claim_1: 'gold' }                         | { claim_3: 'other_value' }                  | false
      { claim_1: 'gold' }                         | {}                                          | false
      { claim_1: 'gold', claim_3: 'other_value' } | { claim_1: 'gold' }                         | false
      { claim_1: 'gold', claim_3: 'other_value' } | { claim_1: 'gold', claim_3: 'other_value' } | true
      { claim_1: ['gold'] }                       | { claim_1: 'gold' }                         | false
      { claim_1: ['gold'] }                       | { claim_1: ['gold'] }                       | true
      {}                                          | { claim_1: 'gold' }                         | false
      nil                                         | { claim_1: 'gold' }                         | false
    end
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
end
