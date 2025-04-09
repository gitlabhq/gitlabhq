# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::StepUpAuthenticationFlow, feature_category: :system_access do
  let(:session) { { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'requested' } } } } }
  let(:provider) { 'openid_connect' }
  let(:scope) { 'admin_mode' }

  subject(:flow) { described_class.new(session: session, provider: provider, scope: scope) }

  describe '#requested?' do
    context 'when state is requested' do
      let(:session) do
        { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'requested' } } } }
      end

      it { is_expected.to be_requested }
    end

    context 'when state is not requested' do
      let(:session) do
        { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'succeeded' } } } }
      end

      it { is_expected.not_to be_requested }
    end
  end

  describe '#succeeded?' do
    context 'when state is authenticated' do
      let(:session) do
        { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'succeeded' } } } }
      end

      it { is_expected.to be_succeeded }
    end

    context 'when state is not authenticated' do
      let(:session) do
        { 'omniauth_step_up_auth' => { provider => { scope => { 'state' => 'requested' } } } }
      end

      it { is_expected.not_to be_succeeded }
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

      it 'sets the state to rejected' do
        expect { evaluate_flow }.to change { flow.rejected? }.from(false).to(true)
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
    it 'sets the state to authenticated' do
      expect { flow.succeed! }.to change { flow.succeeded? }.from(false).to(true)
    end
  end

  describe '#fail!' do
    it 'sets the state to rejected' do
      expect { flow.fail! }.to change { flow.rejected? }.from(false).to(true)
    end
  end
end
