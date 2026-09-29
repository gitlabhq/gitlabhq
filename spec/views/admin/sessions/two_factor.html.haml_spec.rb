# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/sessions/two_factor.html.haml', feature_category: :system_access do
  before do
    assign(:user, user)
  end

  context 'when user has otp active' do
    let(:user) { create(:admin, :two_factor) }

    it 'renders the Vue root element' do
      render

      expect(rendered).to have_selector('#js-2fa[data-totp-enabled="true"]')
    end
  end

  context 'when user has WebAuthn active' do
    let(:user) { create(:admin, :two_factor_via_webauthn) }

    it 'renders the 2FA Vue root element' do
      render

      expect(rendered).to have_selector('#js-2fa[data-webauthn-enabled="true"]')
    end
  end
end
