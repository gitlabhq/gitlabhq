# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::StepUpAuthenticationFlow, feature_category: :system_access do
  include ActiveSupport::Testing::TimeHelpers

  let(:session) { { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'requested' } } } } }
  let(:provider) { 'openid_connect' }
  let(:scope) { 'admin_mode' }

  subject(:flow) { described_class.new(session: session, provider: provider, scope: scope) }

  describe '#initialize' do
    using RSpec::Parameterized::TableSyntax

    shared_examples 'a valid flow' do
      it { is_expected.to have_attributes(scope: scope) }
    end

    shared_examples 'an invalid flow' do
      it 'raises an error' do
        expect { flow }
          .to raise_error(ArgumentError, "Invalid scope '#{scope}'. Allowed scopes are: admin_mode, namespace")
      end
    end

    where(:scope, :expected_example) do
      'admin_mode'   | 'a valid flow'
      :admin_mode    | 'a valid flow'
      'namespace'    | 'a valid flow'
      :namespace     | 'a valid flow'
      'custom_scope' | 'an invalid flow'
      :invalid_scope | 'an invalid flow'
      nil            | 'an invalid flow'
    end

    with_them do
      it_behaves_like params[:expected_example]
    end
  end

  describe '#requested?, #succeeded?, #failed?, #expired?' do
    using RSpec::Parameterized::TableSyntax

    let(:session) { { 'omniauth_step_up_auth' => step_up_auth_session } }
    let(:expiration_data) { { 'exp_timestamp' => 1.hour.ago.to_i } }

    # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
    where(:step_up_auth_session, :provider, :scope, :expected_requested?, :expected_succeeded?, :expected_failed?, :expected_expired?) do
      { 'openid_connect' => { 'admin_mode' => { 'state' => 'requested' } } }                             | 'openid_connect' | :admin_mode | true  | false | false | false
      { 'openid_connect' => { 'admin_mode' => { 'state' => 'succeeded' } } }                             | 'openid_connect' | :admin_mode | false | true  | false | false
      { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } } }                                | 'openid_connect' | :admin_mode | false | false | true | false
      { 'openid_connect' => { 'admin_mode' => { 'state' => 'expired' } } }                               | 'openid_connect' | :admin_mode | false | false | false | true
      { 'openid_connect' => { 'admin_mode' => {} } }                                                     | 'openid_connect' | :admin_mode | false | false | false | false
      { 'openid_connect' => { 'namespace' => { 'state' => 'succeeded' } } }                              | 'openid_connect' | :admin_mode | false | false | false | false
      { 'openid_connect' => { 'namespace' => { 'state' => 'succeeded' } } }                              | 'openid_connect' | :namespace  | false | true  | false | false
      { 'openid_connect' => { 'namespace' => { 'state' => 'expired' } } }                                | 'openid_connect' | :namespace  | false | false | false | true
      { 'openid_connect' => {} }                                                                         | 'openid_connect' | :admin_mode | false | false | false | false
      { 'other_provider' => { 'admin_mode' => { 'state' => 'requested' } } }                             | 'openid_connect' | :admin_mode | false | false | false | false
      { 'other_provider' => { 'admin_mode' => { 'state' => 'succeeded' } } }                             | 'openid_connect' | :admin_mode | false | false | false | false
      { 'other_provider' => { 'admin_mode' => { 'state' => 'expired' } } }                               | 'openid_connect' | :admin_mode | false | false | false | false
      {}                                                                                                 | 'openid_connect' | :admin_mode | false | false | false | false
      nil                                                                                                | 'openid_connect' | :admin_mode | false | false | false | false

      # With expiration
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'requested', **expiration_data } } } } | 'openid_connect' | :admin_mode | true  | false | false | true
      lazy { { 'openid_connect' => { 'admin_mode' => { 'state' => 'succeeded', **expiration_data } } } } | 'openid_connect' | :admin_mode | false | false | false | true
      lazy { { 'openid_connect' => { 'namespace' => { 'state' => 'expired', **expiration_data } } } }    | 'openid_connect' | :namespace  | false | false | false | true
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'has the expected attributes' do
        expect(flow).to have_attributes(
          requested?: expected_requested?,
          succeeded?: expected_succeeded?,
          failed?: expected_failed?,
          expired?: expected_expired?)
      end
    end
  end

  describe '#enabled_by_config?' do
    before do
      allow(::Gitlab::Auth::Oidc::StepUpAuthentication).to receive(:enabled_for_provider?).and_return(true)
    end

    it { is_expected.to be_enabled_by_config }

    context 'when not enabled by config' do
      before do
        allow(::Gitlab::Auth::Oidc::StepUpAuthentication).to receive(:enabled_for_provider?).and_return(false)
      end

      it { is_expected.not_to be_enabled_by_config }
    end
  end

  describe '#evaluate!' do
    let(:oidc_id_token_claims) { { 'claim_1' => 'gold' } }

    subject(:evaluate_flow) { flow.evaluate!(oidc_id_token_claims) }

    context 'when conditions are fulfilled' do
      before do
        allow(::Gitlab::Auth::Oidc::StepUpAuthentication).to receive(:conditions_fulfilled?).and_return(true)
      end

      it 'sets the state to authenticated' do
        expect { evaluate_flow }.to change { flow.succeeded? }.from(false).to(true)
      end
    end

    context 'when conditions are not fulfilled' do
      before do
        allow(::Gitlab::Auth::Oidc::StepUpAuthentication).to receive(:conditions_fulfilled?).and_return(false)
      end

      it 'sets the state to authenticated' do
        expect { evaluate_flow }.not_to change { flow.succeeded? }
      end

      it 'sets the state to failed' do
        expect { evaluate_flow }.to change { flow.failed? }.from(false).to(true)
      end
    end
  end

  describe '#request!' do
    let(:session) { { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'requested' } } } } }

    it 'does not change the state' do
      expect { flow.request! }.not_to change { flow.requested? }
    end

    context 'when the state is authenticated' do
      let(:session) { { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'succeeded' } } } } }

      it 'does not change the state' do
        expect { flow.request! }.to change { flow.requested? }.from(false).to(true)
      end
    end
  end

  describe '#succeed!' do
    let(:current_time) { Time.current }
    let(:exp_timestamp) { current_time.to_i + 30.minutes.to_i }

    around do |example|
      travel_to(current_time) { example.run }
    end

    context 'when oidc_id_token_claims contains exp claim' do
      let(:oidc_id_token_claims) { { 'exp' => exp_timestamp } }

      it 'sets the state to authenticated and includes expiration data' do
        expect { flow.succeed!(oidc_id_token_claims) }.to change { flow.succeeded? }.from(false).to(true)

        session_data = session.dig('omniauth_step_up_auth', provider, scope)
        expect(session_data['exp_timestamp']).to eq(exp_timestamp)
      end
    end

    context 'when oidc_id_token_claims does not contain exp claim' do
      let(:oidc_id_token_claims_without_exp) { { 'other_claim' => 'value' } }

      it 'sets the state to authenticated without expiration data' do
        expect { flow.succeed!(oidc_id_token_claims_without_exp) }.to change { flow.succeeded? }.from(false).to(true)

        session_data = session.dig('omniauth_step_up_auth', provider, scope)
        expect(session_data.keys).not_to include('exp_timestamp')
      end
    end

    it 'sets the state to authenticated' do
      expect { flow.succeed! }.to change { flow.succeeded? }.from(false).to(true)
    end
  end

  describe '#fail!' do
    it 'sets the state to failed' do
      expect { flow.fail! }.to change { flow.failed? }.from(false).to(true)
    end
  end

  describe '#documentation_link' do
    using RSpec::Parameterized::TableSyntax

    let(:provider_name) { 'openid_connect' }
    let(:scope) { 'admin_mode' }
    let(:session) { {} }

    let(:omniauth_provider_config) do
      GitlabSettings::Options.new(
        name: 'openid_connect',
        **provider_config
      )
    end

    subject(:flow) { described_class.new(session: session, provider: provider_name, scope: scope) }

    before do
      stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config])
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting to ensure one-line table syntax
    where(:provider_config, :provider_name, :scope, :expected_result) do
      { 'step_up_auth' => { 'admin_mode' => { 'documentation_link' => 'https://example.com/company/internal/auth-help' } } }          | 'openid_connect' | 'admin_mode'   | 'https://example.com/company/internal/auth-help'
      { 'step_up_auth' => { 'admin_mode' => { 'documentation_link' => 'https://example.com/company/internal/auth-help' } } }          | :openid_connect  | 'admin_mode'   | 'https://example.com/company/internal/auth-help'
      { 'step_up_auth' => { 'namespace' => { 'documentation_link' => 'https://example.com/company/internal/namespace-auth-help' } } } | 'openid_connect' | 'namespace'    | 'https://example.com/company/internal/namespace-auth-help'
      { 'step_up_auth' => { 'admin_mode' => {} } }                                                                                    | 'openid_connect' | 'admin_mode'   | nil
      {}                                                                                                                              | 'openid_connect' | 'admin_mode'   | nil
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'returns the correct documentation link' do
        expect(flow.documentation_link).to eq(expected_result)
      end
    end
  end
end
