# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_passkeys_2fa.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:passkey) { build_stubbed(:webauthn_registration, :passkey, user: user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when the user has a passkey but not a 2FA method' do
    before do
      assign(:passkeys, [passkey])
      allow(user).to receive(:two_factor_enabled?).and_return(false)
    end

    it 'displays a CRUD component with a disabled button' do
      render

      crud_title = s_('ProfilesAuthentication|Passkeys')
      crud_count = 1
      crud_actions_button_text = s_('ProfilesAuthentication|Use passkey as 2FA')
      crud_actions_tooltip =
        s_('ProfilesAuthentication|Register another 2FA method above to automatically use passkeys as default 2FA.')

      expect(rendered).to have_css("[data-testid='crud-title']", text: crud_title)
      expect(rendered).to have_css("[data-testid='crud-count'] span", text: crud_count)
      expect(rendered).to have_css(
        "[data-testid='crud-actions'] .has-tooltip[title='#{crud_actions_tooltip}'][tabindex=0] .gl-button[disabled]",
        text: crud_actions_button_text
      )
    end

    context 'when passkey authentication is disabled for user' do
      before do
        allow(user).to receive(:allow_passkey_authentication?).and_return(false)
      end

      it 'does not display a CRUD component' do
        render

        expect(rendered).to eq("")
      end
    end
  end

  context 'when the user has a passkey and a 2FA method' do
    before do
      assign(:passkeys, [passkey])
      allow(user).to receive(:two_factor_enabled?).and_return(true)
    end

    it 'does not display a CRUD component' do
      render

      expect(rendered).to eq("")
    end
  end

  context 'when the user does not have passkeys and a 2FA method' do
    before do
      assign(:passkeys, [])
      allow(user).to receive(:two_factor_enabled?).and_return(false)
    end

    it 'does not display a CRUD component' do
      render

      expect(rendered).to eq("")
    end
  end
end
