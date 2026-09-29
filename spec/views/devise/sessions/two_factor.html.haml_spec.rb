# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/two_factor.html.haml', feature_category: :system_access do
  before do
    assign(:user, user)
  end

  context 'when user has otp active' do
    let(:user) { create(:user, :two_factor) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- 2FA traits populate via create callbacks; build_stubbed unusable

    it 'renders the Vue root element' do
      render

      expect(rendered).to have_selector('#js-2fa[data-totp-enabled="true"]')
    end
  end

  context 'when user has WebAuthn active' do
    let(:user) { create(:user, :two_factor_via_webauthn) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- 2FA traits populate via create callbacks; build_stubbed unusable

    it 'renders the 2FA Vue root element' do
      render

      expect(rendered).to have_selector('#js-2fa[data-webauthn-enabled="true"]')
    end
  end

  context 'when user has a passkey but no second-factor WebAuthn registration' do
    # This user is passkey_via_2fa_enabled? (TOTP makes them two_factor_enabled?, plus a passkey)
    # but not two_factor_webauthn_enabled?. The screen must still treat them as WebAuthn-capable
    # via can_use_existing_webauthn_authenticator_for_2fa? and default to the security-device
    # screen rather than the OTP screen. Guards against narrowing webauthn_enabled back to
    # two_factor_webauthn_enabled?, which would strand these users on the OTP screen.
    let(:user) do
      create(:user, :two_factor).tap do |u| # rubocop:disable RSpec/FactoryBot/AvoidCreate -- 2FA traits populate via create callbacks; build_stubbed unusable
        create(:webauthn_registration, :passkey, user: u) # rubocop:disable RSpec/FactoryBot/AvoidCreate -- persisted so passkey_via_2fa_enabled? is true
      end
    end

    it 'enables WebAuthn on the 2FA Vue root element' do
      render

      expect(rendered).to have_selector('#js-2fa[data-webauthn-enabled="true"]')
    end
  end
end
