# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_passkeys.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:passkey) { build_stubbed(:webauthn_registration, :passkey, user: user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:passkeys, [passkey])
  end

  it 'renders the correct url' do
    render

    expect(rendered).to have_link(nil, href: new_profile_passkey_path(entry_point: 1))
  end
end
