# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_default_2fa_method.html.haml', feature_category: :system_access do
  let_it_be(:user) { create(:user, :two_factor_via_otp) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- otp trait needs :create
  let_it_be(:second_factor_authenticator) { build_stubbed(:webauthn_registration, :second_factor, user: user) }
  let_it_be(:passkey) { build_stubbed(:webauthn_registration, :passkey, user: user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when the user has a passkey and a 2FA method' do
    before do
      assign(:passkeys, [passkey])
    end

    it 'displays a passkey badge as default 2FA method' do
      render

      expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|Passkey'))
    end

    context 'when passkey authentication is disabled for user' do
      before do
        allow(user).to receive(:allow_passkey_authentication?).and_return(false)
      end

      it 'displays an OTP badge as default 2FA method' do
        render

        expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|One-time password authenticator'))
      end
    end
  end

  context 'when the user has a WebAuthn device' do
    before do
      assign(:registrations, [second_factor_authenticator])
    end

    it 'displays a webauthn badge as default 2FA method' do
      render

      expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|WebAuthn device'))
    end
  end

  context 'when the user has a OTP authenticator' do
    it 'displays an OTP badge as default 2FA method' do
      render

      expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|One-time password authenticator'))
    end

    context 'when :passkeys feature flag is disabled' do
      before do
        stub_feature_flags(passkeys: false)
      end

      it 'does not display default 2FA method badge' do
        render

        expect(rendered).to eq("")
      end
    end
  end

  context 'when the user does not have a 2FA method' do
    let_it_be(:user) { build_stubbed(:user) }

    it 'does not display default 2FA method badge' do
      render

      expect(rendered).to eq("")
    end
  end
end
