# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_passkeys.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:passkey) { build_stubbed(:webauthn_registration, :passkey, user: user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when passkey authentication is disabled for user' do
    before do
      allow(user).to receive(:allow_passkey_authentication?).and_return(false)
    end

    context 'when user has no passkeys' do
      before do
        assign(:passkeys, [])
        render
      end

      it 'does not show the add passkey button' do
        expect(rendered).not_to have_link(s_('ProfilesAuthentication|Add passkey'))
      end

      it 'shows a notice' do
        expect(rendered).to have_css('.gl-alert', text: s_('ProfilesAuthentication|Passkeys unavailable'))
        expect(rendered).to have_text('Passkey sign-in has been restricted for your account.')
      end

      it 'shows no passkeys message' do
        expect(rendered).to have_css('td', text: s_('ProfilesAuthentication|No passkeys added.'))
      end
    end

    context 'when user has passkeys and 2FA disabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        assign(:passkeys, [passkey])
        render
      end

      it 'shows passkeys in the table' do
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Name')}']", text: passkey.name)
      end

      it 'shows a notice' do
        expect(rendered).to have_css('.gl-alert', text: s_('ProfilesAuthentication|Passkeys unavailable'))
        expect(rendered).to have_text('Passkey sign-in has been restricted for your account.')
      end
    end

    context 'when user has passkeys and 2FA enabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
        assign(:passkeys, [passkey])
        render
      end

      it 'shows passkeys in the table' do
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Name')}']", text: passkey.name)
      end

      it 'shows a notice' do
        expect(rendered).to have_css('.gl-alert', text: s_('ProfilesAuthentication|Passkeys unavailable'))
        expect(rendered).to have_text('Passkey sign-in has been restricted for your account.')
        expect(rendered).to have_text(
          'Register your passkeys as a WebAuthn device to continue using them for two-factor authentication.'
        )
      end
    end
  end

  context 'when passkey authentication is enabled for user' do
    before do
      allow(user).to receive(:allow_passkey_authentication?).and_return(true)
    end

    context 'when user has no passkeys' do
      before do
        assign(:passkeys, [])
        render
      end

      it 'show an empty table with the `add passkey` button' do
        expect(rendered).to have_link(s_('ProfilesAuthentication|Add passkey'),
          href: new_profile_passkey_path(entry_point: 1))
        expect(rendered).to have_css('td', text: s_('ProfilesAuthentication|No passkeys added.'))
      end
    end

    context 'when user has passkeys' do
      before do
        assign(:passkeys, [passkey])
        render
      end

      it 'show a table with the `add passkey` button' do
        expect(rendered).to have_link(s_('ProfilesAuthentication|Add passkey'),
          href: new_profile_passkey_path(entry_point: 1))
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Name')}']", text: passkey.name)
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Added on')}']",
          text: l(passkey.created_at.to_date, format: :admin).strip)
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Last used')}']:empty")
        expect(rendered).to have_css("td[data-label='#{_('Actions')}'] .js-two-factor-action-confirm")
      end
    end
  end
end
