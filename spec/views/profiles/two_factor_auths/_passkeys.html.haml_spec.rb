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
      assign(:passkeys, [])
      render
    end

    it 'shows a disabled passkey button' do
      expect(rendered).to have_css('a[disabled]', text: s_('ProfilesAuthentication|Add passkey'))
    end

    it 'shows an alert' do
      expect(rendered).to have_css('.gl-alert', text: s_('ProfilesAuthentication|Passkeys unavailable'))
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

      it 'shows a passkey button with correct url' do
        expect(rendered).to have_link(s_('ProfilesAuthentication|Add passkey'),
          href: new_profile_passkey_path(entry_point: 1))
      end

      it 'show an empty table' do
        expect(rendered).to have_css('td', text: s_('ProfilesAuthentication|No passkeys added.'))
      end
    end

    context 'when user has passkeys' do
      before do
        assign(:passkeys, [passkey])
        render
      end

      it 'show a table' do
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Name')}']", text: passkey.name)
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Added on')}']",
          text: l(passkey.created_at.to_date, format: :admin).strip)
        expect(rendered).to have_css("td[data-label='#{s_('ProfilesAuthentication|Last used')}']:empty")
        expect(rendered).to have_css("td[data-label='#{_('Actions')}'] .js-two-factor-action-confirm")
      end
    end
  end
end
