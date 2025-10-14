# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/sessions/two_factor.html.haml', feature_category: :system_access do
  before do
    assign(:user, user)
  end

  context 'user has otp active' do
    let(:user) { create(:admin, :two_factor) }

    it 'shows enter otp form' do
      render

      expect(rendered).to have_field('user[otp_attempt]')
    end
  end

  context 'user has WebAuthn active' do
    let(:user) { create(:admin, :two_factor_via_webauthn) }

    it 'renders the WebAuthn authentication vue root elements' do
      render

      expect(rendered).not_to have_selector('#js-authenticate-token-2fa')
      expect(rendered).to have_selector('#js-authentication-webauthn[data-remember-me="0"]')
    end
  end
end
