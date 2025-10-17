# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::StepUpAuthentication, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let(:omniauth_provider_config) do
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
      stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config])
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
      stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config])
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
      stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config])
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
      lazy { { 'openid_connect' => { 'namespace' => { 'state' => 'succeeded' } }, 'other_provider' => { 'admin_mode' => { 'state' => 'failed' } } } } | false

      nil                                                                                                                                                 | false
      {}                                                                                                                                                  | false
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it { is_expected.to eq expected_result }
    end

    describe '.succeeded? with expiration' do
      include ActiveSupport::Testing::TimeHelpers

      let(:current_time) { Time.current }
      let(:valid_timestamp) { current_time.to_i + 30.minutes.to_i }
      let(:expired_timestamp) { current_time.to_i - 1.hour.to_i }

      let(:session_with_expired_step_up_auth) do
        {
          'omniauth_step_up_auth' => {
            'openid_connect' => {
              'admin_mode' => {
                'state' => 'succeeded',
                'exp_timestamp' => expired_timestamp
              }
            }
          }
        }
      end

      let(:session_with_valid_step_up_auth) do
        {
          'omniauth_step_up_auth' => {
            'openid_connect' => {
              'admin_mode' => {
                'state' => 'succeeded',
                'exp_timestamp' => valid_timestamp
              }
            }
          }
        }
      end

      around do |example|
        travel_to(current_time) { example.run }
      end

      before do
        stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config])
      end

      context 'with required claims configuration' do
        let(:required_id_token_claims) { { 'acr' => 'https://refeds.org/profile/mfa' } }

        it 'returns false for expired sessions even if they were successful' do
          result = described_class.succeeded?(session_with_expired_step_up_auth)
          expect(result).to be false
        end

        it 'returns true for valid non-expired sessions' do
          result = described_class.succeeded?(session_with_valid_step_up_auth)
          expect(result).to be true
        end
      end
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
            'namespace' => { 'state' => 'succeeded' }
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
      stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config])
    end

    it 'removes the step-up auth data for the given scope from all providers' do
      disable_step_up_authentication!

      expect(session['omniauth_step_up_auth']['openid_connect']).not_to have_key('admin_mode')
      expect(session['omniauth_step_up_auth']['openid_connect']).to have_key('namespace')
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
        expect(session['omniauth_step_up_auth']['openid_connect']).to have_key('namespace')
        expect(session['omniauth_step_up_auth']['other_provider']).to have_key('admin_mode')
      end
    end
  end

  describe '.failed_step_up_auth_flows' do
    let(:scope) { 'admin_mode' }
    let(:openid_connect_config) do
      GitlabSettings::Options.new(
        name: 'openid_connect',
        step_up_auth: {
          admin_mode: {
            id_token: {
              required: { claim_1: 'gold' }
            }
          }
        }
      )
    end

    let(:saml_config) do
      GitlabSettings::Options.new(
        name: 'saml',
        step_up_auth: {
          admin_mode: {
            id_token: {
              required: { claim_2: 'silver' }
            }
          }
        }
      )
    end

    let(:auth0_config) do
      GitlabSettings::Options.new(
        name: 'auth0',
        step_up_auth: {
          admin_mode: {
            id_token: {
              required: { claim_3: 'bronze' }
            }
          }
        }
      )
    end

    let(:no_step_up_provider_config) do
      GitlabSettings::Options.new(name: 'no_step_up_provider')
    end

    subject(:failed_flows) { described_class.failed_step_up_auth_flows(session, scope: scope) }

    before do
      stub_omniauth_setting(
        enabled: true,
        providers: [openid_connect_config, saml_config, auth0_config, no_step_up_provider_config]
      )
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting to ensure one-line table syntax
    where(:session, :scope, :expected_providers) do
      { 'omniauth_step_up_auth' => { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } }, 'saml' => { 'admin_mode' => { 'state' => 'succeeded' } }, 'auth0' => { 'admin_mode' => { 'state' => 'failed' } } } } | 'admin_mode'  | %w[openid_connect auth0]
      { 'omniauth_step_up_auth' => { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' }, 'other_scope' => { 'state' => 'succeeded' } } } }                                                                      | 'other_scope' | []
      { 'omniauth_step_up_auth' => { 'openid_connect' => { 'other_scope' => { 'state' => 'failed' } } } }                                                                                                                  | 'admin_mode'  | []
      { 'omniauth_step_up_auth' => { 'openid_connect' => { 'admin_mode' => {} }, 'saml' => { 'admin_mode' => { 'state' => 'failed' } } } }                                                                                 | 'admin_mode'  | ['saml']
      { 'omniauth_step_up_auth' => { 'no_step_up_provider' => { 'admin_mode' => { 'state' => 'failed' } } } }                                                                                                              | 'admin_mode'  | []
      { 'omniauth_step_up_auth' => { 'no_step_up_provider' => { 'admin_mode' => { 'state' => 'failed' } }, 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } } } }                                             | 'admin_mode'  | ['openid_connect']
      { 'omniauth_step_up_auth' => nil }                                                                                                                                                                                   | 'admin_mode'  | []
      {}                                                                                                                                                                                                                   | 'admin_mode'  | []
      nil                                                                                                                                                                                                                  | 'admin_mode'  | []
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'returns flow objects for the expected providers' do
        expect(failed_flows.map(&:provider)).to match_array(expected_providers)
      end

      it { is_expected.to all be_a(Gitlab::Auth::Oidc::StepUpAuthenticationFlow) }

      it { is_expected.to all be_failed.and(be_enabled_by_config) }
    end
  end

  describe '.enabled_providers' do
    subject { described_class.enabled_providers(scope: scope) }

    let(:omniauth_provider_oidc) do
      GitlabSettings::Options.new(
        name: "openid_connect",
        step_up_auth: {
          admin_mode: {
            id_token: {
              required: {
                acr: 'gold'
              }
            }
          },
          namespace: {
            id_token: {
              required: {
                acr: 'gold'
              }
            }
          }
        }
      )
    end

    let(:omniauth_provider_oidc_only_namespace) do
      GitlabSettings::Options.new(
        name: "openid_connect_aad",
        step_up_auth: {
          namespace: {
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
      stub_omniauth_setting(enabled: true, providers: provider_configs)
      allow(Devise).to receive(:omniauth_providers).and_return(provider_configs.map(&:name))
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting to ensure one-line table syntax
    where(:scope, :provider_configs, :expected_result) do
      :admin_mode    | [ref(:omniauth_provider_oidc)]                                              | ['openid_connect']
      'admin_mode'   | [ref(:omniauth_provider_oidc)]                                              | ['openid_connect']
      :admin_mode    | [ref(:omniauth_provider_oidc_only_namespace)]                               | []
      :namespace     | [ref(:omniauth_provider_oidc), ref(:omniauth_provider_oidc_only_namespace)] | %w[openid_connect openid_connect_aad]
      'namespace'    | [ref(:omniauth_provider_oidc)]                                              | ['openid_connect']
      :namespace     | [ref(:omniauth_provider_oidc)]                                              | ['openid_connect']
      :namespace     | []                                                                          | []
      :unknown_scope | [ref(:omniauth_provider_oidc), ref(:omniauth_provider_oidc_only_namespace)] | []
      nil            | [ref(:omniauth_provider_oidc), ref(:omniauth_provider_oidc_only_namespace)] | []
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it { is_expected.to match_array(expected_result) }
    end
  end
end
