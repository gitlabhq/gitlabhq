# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/passwords/edit.html.haml', feature_category: :system_access do
  include SafeFormatHelper

  let_it_be(:user_with_passkeys) { create(:user, :two_factor_via_webauthn) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- User is needed
  let_it_be(:user_without_passkeys) { build_stubbed(:user) }

  context 'when the user has a passkey' do
    before do
      assign(:user, user_with_passkeys)
    end

    it 'displays an alert to manage passkeys' do
      render

      two_factor_link = link_to('', profile_two_factor_auth_path)
      expect(rendered).to include(safe_format(s_('ProfilesAuthentication|You currently use passkeys for secure and ' \
        'faster sign in. %{link_start}Manage passkeys%{link_end}.'), tag_pair(two_factor_link, :link_start, :link_end)))
    end
  end

  context "when the user doesn't have passkeys" do
    before do
      assign(:user, user_without_passkeys)
    end

    it 'displays an alert to add passkeys with a learn more link' do
      render

      expect(rendered).to include('Add a passkey to sign in securely with your trusted device. ' \
        '<a target="_blank" rel="noreferrer" href="/help/auth/passkeys.md">Learn more about passkeys</a>.')
    end

    it 'displays an `Add passkey` button' do
      render

      expect(rendered).to have_css("a.btn-confirm[href=\"#{new_profile_passkey_path}\"]",
        text: s_('ProfilesAuthentication|Add passkey'))
    end
  end
end
