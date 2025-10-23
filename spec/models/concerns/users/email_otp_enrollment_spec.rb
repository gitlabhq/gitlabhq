# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailOtpEnrollment, feature_category: :system_access do
  let(:email_otp_required_after) { Time.current }
  let(:user) { create(:user, email_otp_required_after: email_otp_required_after) }
  let(:group_require_two_factor_authentication) { false }
  let(:group) { create(:group, require_two_factor_authentication: group_require_two_factor_authentication) }

  before do
    # Adding a user to a group with 2FA requirement triggers
    # side-effects that we want to ensure are accounted for.
    # Otherwise, we skip #reload for spec performance.
    group.add_developer(user)
    user.reload if group_require_two_factor_authentication
  end

  describe '#can_modify_email_otp_enrollment?' do
    subject { user.can_modify_email_otp_enrollment? }

    it 'returns true when no restriction exists' do
      allow(user).to receive(:email_otp_enrollment_restriction).and_return(nil)
      is_expected.to be true
    end

    it 'returns false when restriction exists' do
      allow(user).to receive(:email_otp_enrollment_restriction).and_return(:some_restriction)
      is_expected.to be false
    end
  end

  describe '#email_otp_enrollment_restriction' do
    subject { user.email_otp_enrollment_restriction }

    # By default the user is unrestricted and can opt in and out of
    # Email-based OTP
    it { is_expected.to be_nil }

    context 'when user has email OTP required and has other MFA enabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
      end

      # No restrictions
      it { is_expected.to be_nil }
    end

    context 'when user uses an external authenticator and has no GitLab password' do
      before do
        allow(user).to receive(:password_automatically_set).and_return(true)
      end

      it { is_expected.to eq(:uses_external_authenticator) }
    end

    context 'when group enforces 2FA' do
      let(:group_require_two_factor_authentication) { true }

      it { is_expected.to eq(:group_enforcement) }
    end

    context 'when instance enforces 2FA' do
      before do
        stub_application_setting(require_two_factor_authentication: true)
      end

      it { is_expected.to eq(:global_enforcement) }
    end

    context 'when user is an admin with admin enforcement' do
      before do
        user.update!(admin: true)
        stub_application_setting(require_admin_two_factor_authentication: true)
      end

      it { is_expected.to eq(:admin_2fa_enforcement) }
    end

    context 'when email OTP enforcement is in the future' do
      let(:email_otp_required_after) { 1.day.from_now }

      it { is_expected.to eq(:future_enforcement) }
    end

    context 'when instance enforces email OTP as a minimum' do
      before do
        stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)
      end

      it { is_expected.to eq(:email_otp_required) }

      context 'when user has 2FA' do
        before do
          allow(user).to receive(:two_factor_enabled?).and_return(true)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#must_require_email_otp?' do
    before do
      stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)
    end

    subject { user.must_require_email_otp? }

    it { is_expected.to be true }

    context 'when user does not use a password' do
      before do
        allow(user).to receive(:password_automatically_set).and_return(true)
      end

      it { is_expected.to be false }
    end

    context 'when user has 2FA' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
      end

      it { is_expected.to be false }
    end
  end
end
