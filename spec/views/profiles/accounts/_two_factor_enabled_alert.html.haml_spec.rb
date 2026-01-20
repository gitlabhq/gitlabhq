# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/accounts/_two_factor_enabled_alert.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }

  context 'when URL does not contain two_factor_auth_enabled_successfully query parameter' do
    it 'empty string' do
      render
      expect(rendered).to have_text('')
    end
  end

  context 'when URL contains two_factor_auth_enabled_successfully query parameter' do
    before do
      allow(view).to receive_messages(current_user: user, params: { two_factor_auth_enabled_successfully: true })
    end

    context 'when user has passkeys' do
      before do
        allow(user).to receive(:passkey_via_2fa_enabled?).and_return(true)
        render
      end

      it 'renders correct banner text' do
        expect(rendered).to have_text('2FA setup complete! Passkey is now your default 2FA method. If you lose ' \
          'access to your 2FA method, use your recovery codes.')
      end

      it 'has a button that remove the query parameter' do
        expect(rendered).to have_css('.js-close-2fa-enabled-success-alert')
      end
    end

    context 'when user does not have passkeys' do
      before do
        allow(user).to receive(:passkey_via_2fa_enabled?).and_return(false)
        render
      end

      it 'renders correct banner text' do
        expect(rendered).to have_text('2FA setup complete! If you lose access to your 2FA method, use your recovery ' \
          'codes.')
      end
    end
  end
end
