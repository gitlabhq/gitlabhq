# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_default_2fa_method.html.haml', feature_category: :system_access do
  let_it_be(:user) { create(:user, :two_factor) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- User is needed

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when the user has a passkey' do
    it 'displays a passkey badge as default 2FA method' do
      render

      expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|Passkey'))
    end
  end

  # context 'when the user has a WebAuthn device' do
  #   before do
  #     assign(:passkeys, [])
  #     assign(:registrations, ['webauthn'])
  #   end

  #   it 'displays a webauthn badge as default 2FA method' do  #     render

  #     expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|WebAuthn device'))
  #   end
  # end

  # context 'when the user has a OTP authenticator' do
  #   before do
  #     assign(:passkeys, [])
  #   end

  #   it 'displays an OTP badge as default 2FA method' do
  #     render

  #     expect(rendered).to have_css('.gl-badge', text: s_('ProfilesAuthentication|One-time password authenticator'))
  #   end
  # end
end
