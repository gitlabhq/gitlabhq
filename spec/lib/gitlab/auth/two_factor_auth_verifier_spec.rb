# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::TwoFactorAuthVerifier do
  using RSpec::Parameterized::TableSyntax

  let(:request) { instance_double(ActionDispatch::Request, session: session) }
  let(:session) { {} }

  let(:user) { build_stubbed(:user, otp_grace_period_started_at: Time.zone.now) }

  subject(:verifier) { described_class.new(user, request) }

  describe '#two_factor_authentication_enforced?' do
    subject { verifier.two_factor_authentication_enforced? }

    where(:instance_level_enabled, :group_level_enabled, :grace_period_expired, :should_be_enforced) do
      false | false | true  | false
      true  | false | false | false
      true  | false | true  | true
      false | true  | false | false
      false | true  | true  | true
    end

    with_them do
      before do
        stub_application_setting(require_two_factor_authentication: instance_level_enabled)
        allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(group_level_enabled)
        stub_application_setting(two_factor_grace_period: grace_period_expired ? 0 : 1.month.in_hours)
      end

      it { is_expected.to eq(should_be_enforced) }
    end
  end

  describe '#two_factor_authentication_required?' do
    subject { verifier.two_factor_authentication_required? }

    where(:instance_level_enabled, :group_level_enabled, :should_be_required, :provider_2FA) do
      true  | false | true | false
      false | true  | false | true
      false | true  | true | false
      false | false | false | true
    end

    with_them do
      before do
        stub_application_setting(require_two_factor_authentication: instance_level_enabled)
        allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(group_level_enabled)
        session[:provider_2FA] = provider_2FA
      end

      it { is_expected.to eq(should_be_required) }
    end

    context 'when request is nil' do
      let(:request) { nil }

      where(:instance_level_enabled, :group_level_enabled, :should_be_required, :provider_2FA) do
        true  | false | true | false
        false | true  | true | true
        false | false | false | true
      end

      with_them do
        before do
          allow(request).to receive(:session).and_return(session)
          stub_application_setting(require_two_factor_authentication: instance_level_enabled)
          allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(group_level_enabled)
          session[:provider_2FA] = provider_2FA
        end

        it { is_expected.to eq(should_be_required) }
      end
    end
  end

  describe '#current_user_needs_to_setup_two_factor?' do
    it 'returns false when current_user is nil' do
      expect(described_class.new(nil, request).current_user_needs_to_setup_two_factor?).to be_falsey
    end

    it 'returns false when current_user does not have temp email' do
      allow(user).to receive(:two_factor_enabled?).and_return(false)
      allow(user).to receive(:temp_oauth_email?).and_return(true)

      expect(subject.current_user_needs_to_setup_two_factor?).to be_falsey
    end

    it 'returns false when current_user has 2fa disabled' do
      allow(user).to receive(:temp_oauth_email?).and_return(false)
      allow(user).to receive(:two_factor_enabled?).and_return(true)

      expect(subject.current_user_needs_to_setup_two_factor?).to be_falsey
    end

    it 'returns true when user requires 2fa authentication' do
      allow(user).to receive(:two_factor_enabled?).and_return(false)
      allow(user).to receive(:temp_oauth_email?).and_return(false)

      expect(subject.current_user_needs_to_setup_two_factor?).to be_truthy
    end
  end

  describe '#two_factor_grace_period' do
    it 'returns grace period from settings if there is no period from groups' do
      stub_application_setting two_factor_grace_period: 2
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(false)

      expect(subject.two_factor_grace_period).to eq(2)
    end

    it 'returns grace period from groups if there is no period from settings' do
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)
      allow(user).to receive(:two_factor_grace_period).and_return(3)

      expect(subject.two_factor_grace_period).to eq(3)
    end

    it 'returns minimal grace period if there is grace period from settings and from group' do
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)
      allow(user).to receive(:two_factor_grace_period).and_return(3)
      stub_application_setting two_factor_grace_period: 2

      expect(subject.two_factor_grace_period).to eq(2)
    end
  end

  describe '#two_factor_grace_period_expired?' do
    it 'returns true if the grace period has expired' do
      stub_application_setting two_factor_grace_period: 0

      expect(subject.two_factor_grace_period_expired?).to be_truthy
    end

    it 'returns false if the grace period has not expired' do
      stub_application_setting two_factor_grace_period: 1.month.in_hours

      expect(subject.two_factor_grace_period_expired?).to be_falsey
    end

    context 'when otp_grace_period_started_at is nil' do
      it 'returns false' do
        user.otp_grace_period_started_at = nil

        expect(subject.two_factor_grace_period_expired?).to be_falsey
      end
    end
  end

  describe '#two_factor_authentication_reason?' do
    it 'returns false if two factor authentication is not required' do
      allow(user).to receive(:require_two_factor_authentication?).and_return(false)

      expect(subject.two_factor_authentication_reason).to be_falsey
    end

    it 'returns :global if two factor authentication is enabled globally' do
      stub_application_setting require_two_factor_authentication: true

      expect(subject.two_factor_authentication_reason).to eq(:global)
    end

    it 'returns :admin_2fa if the current user is an admin and two factor is enabled' do
      stub_application_setting require_admin_two_factor_authentication: true

      allow(user).to receive(:admin?).and_return(true)

      expect(subject.two_factor_authentication_reason).to eq(:admin_2fa)
    end

    it 'returns :group if two factor authentication is enforced through a group setting' do
      stub_application_setting require_two_factor_authentication: false
      allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(true)

      expect(subject.two_factor_authentication_reason).to eq(:group)
    end
  end
end
