# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VerifiesWithEmailHelper, feature_category: :system_access do
  include Devise::Test::ControllerHelpers

  let(:user_unlock_token) { nil }
  let(:user) { build_stubbed(:user, unlock_token: user_unlock_token) }
  let(:today) { Time.zone.parse('2025-09-10') }

  describe '#trusted_ip_address?' do
    let(:trusted) { false }

    before do
      allow(AuthenticationEvent)
          .to receive(:initial_login_or_known_ip_address?)
          .and_return(trusted)
    end

    subject { helper.trusted_ip_address?(user) }

    context 'when AuthenticationEvent.initial_login_or_known_ip_address returns false' do
      it { is_expected.to be false }
    end

    context 'when AuthenticationEvent.initial_login_or_known_ip_address returns true' do
      let(:trusted) { true }

      it { is_expected.to be true }
    end
  end

  describe '#treat_as_locked?' do
    subject { helper.treat_as_locked?(user) }

    context 'when user access is not locked and has no unlock token' do
      it { is_expected.to be false }
    end

    context 'when user access is locked' do
      before do
        allow(user).to receive(:access_locked?).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'when user unlock token is present' do
      let(:user_unlock_token) { 'some token' }

      it { is_expected.to be true }
    end
  end

  describe '#permitted_to_skip_email_otp_in_grace_period?' do
    let(:trusted_ip) { true }
    let(:user_unlock_token) { nil }
    let(:in_grace_period) { true }

    before do
      allow(AuthenticationEvent)
          .to receive(:initial_login_or_known_ip_address?)
          .and_return(trusted_ip)
      allow(helper).to receive(:in_email_otp_grace_period?).and_return(in_grace_period)
    end

    subject { helper.permitted_to_skip_email_otp_in_grace_period?(user) }

    context 'when all conditions are met' do
      before do
        stub_feature_flags(email_based_mfa: true)
      end

      it { is_expected.to be true }
    end

    context 'when email_based_mfa feature is disabled' do
      before do
        stub_feature_flags(email_based_mfa: false)
      end

      it { is_expected.to be false }
    end

    context 'when user has two factor authentication enabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
      end

      it { is_expected.to be false }
    end

    context 'when IP address is not trusted' do
      let(:trusted_ip) { false }

      it { is_expected.to be false }
    end

    context 'when user is treated as locked due to access_locked' do
      before do
        allow(user).to receive(:access_locked?).and_return(true)
      end

      it { is_expected.to be false }
    end

    context 'when user is treated as locked due to unlock token' do
      let(:user_unlock_token) { 'some_token' }

      it { is_expected.to be false }
    end

    context 'when user is not in email OTP grace period' do
      let(:in_grace_period) { false }

      it { is_expected.to be false }
    end
  end

  describe '#in_email_otp_grace_period?' do
    let(:email_otp_required_after) { today + 15.days }
    let(:user) { build_stubbed(:user, email_otp_required_after: email_otp_required_after) }

    before do
      travel_to(today)
    end

    after do
      travel_back
    end

    subject { helper.send(:in_email_otp_grace_period?, user) }

    context 'when email_otp_required_after is nil' do
      let(:email_otp_required_after) { nil }

      it { is_expected.to be false }
    end

    context 'when email_otp_required_after is in the past' do
      let(:email_otp_required_after) { today - 1.day }

      it { is_expected.to be false }
    end

    context 'when email_otp_required_after equals current date' do
      let(:email_otp_required_after) { today }

      it { is_expected.to be false }
    end

    context 'when at the start of grace period (30 days before required_after)' do
      let(:email_otp_required_after) { today + 30.days }

      it { is_expected.to be true }
    end

    context 'when before grace period starts (31st day before required_after)' do
      let(:email_otp_required_after) { today + 31.days }

      it { is_expected.to be false }
    end
  end
end
