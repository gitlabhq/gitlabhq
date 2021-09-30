# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::TwoFactorAuthVerifier do
  using RSpec::Parameterized::TableSyntax

  subject(:verifier) { described_class.new(user) }

  let(:user) { build_stubbed(:user, otp_grace_period_started_at: Time.zone.now) }

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

    where(:instance_level_enabled, :group_level_enabled, :should_be_required) do
      true  | false | true
      false | true  | true
      false | false | false
    end

    with_them do
      before do
        stub_application_setting(require_two_factor_authentication: instance_level_enabled)
        allow(user).to receive(:require_two_factor_authentication_from_group?).and_return(group_level_enabled)
      end

      it { is_expected.to eq(should_be_required) }
    end
  end

  describe '#current_user_needs_to_setup_two_factor?' do
    it 'returns false when current_user is nil' do
      expect(described_class.new(nil).current_user_needs_to_setup_two_factor?).to be_falsey
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
end
