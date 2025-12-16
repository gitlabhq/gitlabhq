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
    end

    it 'displays a CRUD component with a disabled button' do
      render

      tooltip =
        s_('ProfilesAuthentication|Register another 2FA method above to automatically use passkeys as default 2FA.')
      expect(rendered).to have_css(".gl-button[disabled][title='#{tooltip}']",
        text: s_('ProfilesAuthentication|Use passkey as 2FA'))
      expect(rendered).to include(
        s_('ProfilesAuthentication|Register another 2FA method above to automatically use passkeys as default 2FA.'))
    end
  end
end
