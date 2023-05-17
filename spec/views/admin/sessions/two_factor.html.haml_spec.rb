# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/sessions/two_factor.html.haml' do
  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'user has no two factor auth' do
    let(:user) { create(:admin) }

    it 'shows tab' do
      render

      expect(rendered).to have_no_field('user[otp_attempt]')
      expect(rendered).to have_no_field('user[device_response]')
    end
  end

  context 'user has otp active' do
    let(:user) { create(:admin, :two_factor) }

    it 'shows enter otp form' do
      render

      expect(rendered).to have_css('#login-pane.active')
      expect(rendered).to have_field('user[otp_attempt]')
    end
  end

  context 'user has WebAuthn active' do
    let(:user) { create(:admin, :two_factor_via_webauthn) }

    it 'shows enter WebAuthn form' do
      render

      expect(rendered).to have_css('#js-login-2fa-device.btn')
    end
  end
end
