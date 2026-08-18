# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/sessions/two_factor.html.haml', feature_category: :system_access do
  before do
    assign(:user, user)
  end

  context 'when user has otp active' do
    let(:user) { create(:admin, :two_factor) }

    it 'renders the Vue mount point instead of the otp form' do
      render

      expect(rendered).to have_selector('#js-2fa')
      expect(rendered).not_to have_field('user[otp_attempt]')
    end

    context 'when two_factor_vue is disabled' do
      before do
        stub_feature_flags(two_factor_vue: false)
      end

      it 'shows enter otp form' do
        render

        expect(rendered).to have_field('user[otp_attempt]')
      end
    end
  end

  context 'when user has WebAuthn active' do
    let(:user) { create(:admin, :two_factor_via_webauthn) }

    # This WebAuthn admin is not email-OTP eligible, so the relaxed guard routes them to the
    # Vue #js-2fa screen when the flag is on (the default in tests). The legacy HAML mounts
    # live only in the flag-off branch, so none render here.
    it 'renders the 2FA Vue root element' do
      render

      expect(rendered).to have_selector('#js-2fa[data-webauthn-enabled="true"]')
      expect(rendered).not_to have_selector('#js-authentication-webauthn')
    end

    context 'when two_factor_vue is disabled' do
      before do
        stub_feature_flags(two_factor_vue: false)
      end

      it 'renders the legacy WebAuthn authentication root element' do
        render

        expect(rendered).not_to have_selector('#js-2fa')
        expect(rendered).to have_selector('#js-authentication-webauthn[data-remember-me="0"]')
      end
    end
  end
end
