# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/show.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:passkeys, [])
    assign(:qr_code, '')
    assign(:account_string, '')
    assign(:registrations, [])
    assign(:webauthn_registration, build_stubbed(:webauthn_registration, user: user))
    allow(user).to receive_messages(
      otp_secret: 'a' * 32,
      allow_passkey_authentication?: true,
      allow_password_authentication?: true
    )
    allow(view).to receive_messages(
      current_user: user,
      current_password_required?: false,
      display_providers_on_profile?: false,
      button_based_providers: [],
      two_factor_authentication_required?: false,
      two_factor_grace_period_expired?: false,
      disable_two_factor_authentication_data: {},
      email_otp_enrollment_restriction_confirm_data: {}
    )
    stub_feature_flags(passkeys: false, email_based_mfa: false)
  end

  context 'when user is allowed to use passkeys authentication' do
    before do
      render
    end

    it 'does not show the passkey restriction warning in the Manage authentication section' do
      expect(rendered).not_to have_css("[data-testid='page-heading-description']",
        text: 'Password and passkey sign-in have been restricted for your account. Learn more')
    end

    it 'shows the passkey 2FA description in the two-factor authentication section' do
      expect(rendered).to have_css('.settings-sticky-header-description',
        text: s_('ProfilesAuthentication|Enable additional security methods for two-factor authentication. ' \
          'Once enabled, you can also use your passkeys for 2FA.'))
    end
  end

  context 'when user is not allowed to use passkeys for authentication' do
    before do
      allow(user).to receive(:allow_passkey_authentication?).and_return(false)
      render
    end

    it 'shows the passkey restriction warning in the Manage authentication section' do
      expect(rendered).to have_css("[data-testid='page-heading-description']",
        text: 'Password and passkey sign-in have been restricted for your account. Learn more')
    end

    it 'shows a generic description in the two-factor authentication section' do
      expect(rendered).not_to have_css('.settings-sticky-header-description',
        text: s_('ProfilesAuthentication|Enable additional security methods for two-factor authentication. ' \
          'Once enabled, you can also use your passkeys for 2FA.'))
    end
  end

  context 'when user is allowed to use password for authentication' do
    it "renders the 'Change password' button with the correct testid" do
      render
      expect(rendered).to have_link(s_('ProfilesAuthentication|Change password'),
        href: edit_user_settings_password_path)
      expect(rendered).to have_css("a[data-testid='change-password-button']",
        text: s_('ProfilesAuthentication|Change password'))
    end
  end

  context 'when user is not allowed to use password for authentication' do
    before do
      allow(user).to receive(:allow_password_authentication?).and_return(false)
      render
    end

    it "does not render the 'Change password' button" do
      expect(rendered).not_to have_link(s_('ProfilesAuthentication|Change password'),
        href: edit_user_settings_password_path)
      expect(rendered).not_to have_css("a[data-testid='change-password-button']",
        text: s_('ProfilesAuthentication|Change password'))
    end
  end

  context 'for two-factor authentication status' do
    context 'when two-factor authentication is enabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
        render
      end

      it 'displays Active status for two-factor authentication' do
        expect(rendered).to have_text(_('Active'))
      end
    end

    context 'when two-factor authentication is disabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        render
      end

      it 'displays Inactive status for two-factor authentication' do
        expect(rendered).to have_text(_('Inactive'))
      end
    end
  end

  context 'for passkey sign-in status' do
    before do
      stub_feature_flags(passkeys: true)
    end

    context 'when passkeys are active' do
      before do
        assign(:passkeys, [build_stubbed(:webauthn_registration, user: user)])
        render
      end

      it 'displays Active status for passkeys' do
        expect(rendered).to have_text(_('Active'))
      end
    end

    context 'when passkeys are inactive' do
      before do
        assign(:passkeys, [])
        render
      end

      it 'displays Inactive status for passkeys' do
        expect(rendered).to have_text(_('Inactive'))
      end
    end

    context 'when user is not allowed to use passkey authentication' do
      before do
        allow(user).to receive(:allow_passkey_authentication?).and_return(false)
        assign(:passkeys, [build_stubbed(:webauthn_registration, user: user)])
        render
      end

      it 'displays Inactive status for passkeys' do
        expect(rendered).to have_text(_('Inactive'))
      end
    end
  end
end
