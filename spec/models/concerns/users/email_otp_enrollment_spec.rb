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

    context 'when email_based_mfa feature flag is disabled for the user' do
      before do
        stub_feature_flags(email_based_mfa: false)
      end

      # Users are restricted from enabling or disabling the feature
      it { is_expected.to eq(:feature_disabled) }
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

  describe '#set_email_otp_required_after_based_on_restrictions', :freeze_time do
    let(:new_email_otp_required_after) { email_otp_required_after }

    subject(:set_email_otp) do
      user.email_otp_required_after = new_email_otp_required_after
      user.set_email_otp_required_after_based_on_restrictions
    end

    it 'does not perform any checks when email_based_mfa FF is disabled' do
      stub_feature_flags(email_based_mfa: false)
      allow(user).to receive(:must_require_email_otp?).and_call_original
      allow(Gitlab::Auth::TwoFactorAuthVerifier).to receive(:new).and_call_original

      set_email_otp
      expect(user).not_to have_received(:must_require_email_otp?)
      expect(Gitlab::Auth::TwoFactorAuthVerifier).not_to have_received(:new)
    end

    context 'when must_require_email_otp?' do
      before do
        allow(user).to receive(:must_require_email_otp?).and_return(true)
      end

      context 'when email_otp_required_after is being changed from a value to nil' do
        let(:email_otp_required_after) { 30.days.ago }
        let(:new_email_otp_required_after) { nil }

        it 'reverts to the old value' do
          expect { set_email_otp }.to not_change { user.email_otp_required_after }
        end
      end

      context 'when email_otp_required_after is nil' do
        let(:email_otp_required_after) { nil }

        it 'sets it to now' do
          expect { set_email_otp }.to change { user.email_otp_required_after }.to(Time.current)
        end
      end
    end

    context 'when 2FA is required by policy' do
      before do
        allow_next_instance_of(Gitlab::Auth::TwoFactorAuthVerifier) do |verifier|
          allow(verifier).to receive(:two_factor_authentication_required?).and_return(true)
        end
      end

      context 'when user have 2FA' do
        before do
          allow(user).to receive(:two_factor_enabled?).and_return(true)
        end

        context 'when email_otp_required_after is being changed from a value to nil' do
          let(:new_email_otp_required_after) { nil }

          it 'allows it' do
            expect { set_email_otp }.to change { user.email_otp_required_after }.to(nil)
          end
        end

        context 'when email_otp_required_after is being changed to a value' do
          let(:email_otp_required_after) { nil }
          let(:new_email_otp_required_after) { Time.current }

          it 'does not allow it as they must only use 2FA' do
            expect { set_email_otp }.to not_change { user.email_otp_required_after }
          end
        end
      end

      context 'when email_otp_required_after is being changed from a value to nil' do
        let(:new_email_otp_required_after) { nil }

        it 'allows it as there is no minimum requirement for Email OTP' do
          expect { set_email_otp }.to change { user.email_otp_required_after }.to(nil)
        end
      end

      context 'when email_otp_required_after is being changed to a value' do
        let(:email_otp_required_after) { nil }
        let(:new_email_otp_required_after) { Time.current }

        it 'allows it' do
          expect { set_email_otp }.to change { user.email_otp_required_after }.to(Time.current)
        end
      end
    end

    it 'prevents Email OTP when 2FA is required and enabled, and minimum Email OTP requirement is enabled' do
      stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)
      allow_next_instance_of(Gitlab::Auth::TwoFactorAuthVerifier) do |verifier|
        allow(verifier).to receive(:two_factor_authentication_required?).and_return(true)
      end
      allow(user).to receive(:two_factor_enabled?).and_return(true)

      user.email_otp_required_after = Time.current
      set_email_otp
      expect(user.email_otp_required_after).to be_nil
    end

    context 'when a change is made', :freeze_time do
      let(:email_otp_required_after) { nil }
      let(:new_email_otp_required_after) { Time.current }

      it 'logs the change' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "set_email_otp_required_after_based_on_restrictions is modifying email_otp_required_after",
          change: { before: nil, after: Time.current },
          user_id: user.id
        )
        set_email_otp
      end
    end

    context 'when save: true' do
      subject(:set_email_otp) do
        user.email_otp_required_after = new_email_otp_required_after
        user.set_email_otp_required_after_based_on_restrictions(save: true)
      end

      it 'does not call save when no change is made' do
        expect(user).not_to receive(:save)
        set_email_otp
      end

      it 'does not call save when the record is dirty for another attribute' do
        user.user_detail.job_title = 'irrelevant'
        expect(user).not_to receive(:save)
        set_email_otp
      end

      context 'when a change is made', :freeze_time do
        # Set up preconditions for mandatory Email OTP
        let(:email_otp_required_after) { nil }

        before do
          allow(user).to receive(:must_require_email_otp?).and_return(true)
        end

        it 'updates the value in the database' do
          expect { set_email_otp }.to change { user.reload.email_otp_required_after }.to(Time.current)
        end

        it 'logs the failure when save fails', :freeze_time do
          allow(user.user_detail).to receive_messages(
            save: false,
            errors: instance_double(ActiveModel::Errors, full_messages: ['Error message'])
          )

          expect(Gitlab::AppLogger).to receive(:warn).with(
            message: 'set_email_otp_required_after_based_on_restrictions failed to save',
            change: { before: nil, after: Time.current },
            errors: ['Error message']
          )
          set_email_otp
        end
      end
    end
  end
end
