# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/new', feature_category: :system_access do
  describe 'ldap' do
    include LdapHelpers

    let(:server) { { provider_name: 'ldapmain', label: 'LDAP' }.with_indifferent_access }

    before do
      enable_ldap
      stub_devise
      disable_captcha
      disable_sign_up
      disable_other_signin_methods
    end

    it 'is shown when enabled' do
      render

      expect(rendered).to have_selector('#js-signin-tabs')
      expect(rendered).to have_selector('[data-testid="ldap-tab"]')
      expect(rendered).to have_field(_('Username'))
    end

    it 'is not shown when LDAP sign in is disabled' do
      disable_ldap_sign_in

      render

      expect(rendered).to have_content('No authentication methods configured')
      expect(rendered).not_to have_selector('[data-testid="ldap-tab"]')
      expect(rendered).not_to have_field(_('Username'))
    end
  end

  def disable_other_signin_methods
    allow(view).to receive_messages(password_authentication_enabled_for_web?: false, omniauth_enabled?: false)
  end

  def disable_sign_up
    allow(view).to receive(:allow_signup?).and_return(false)
  end

  def stub_devise
    allow(view).to receive_messages(devise_mapping: Devise.mappings[:user], resource: spy, resource_name: :user)
  end

  def enable_ldap
    stub_ldap_setting(enabled: true)
    allow(view).to receive_messages(ldap_servers: [server], form_based_providers: [:ldapmain])
    allow(view).to receive(:omniauth_callback_path).with(:user, 'ldapmain').and_return('/ldapmain')
  end

  def disable_ldap_sign_in
    allow(view).to receive_messages(ldap_sign_in_enabled?: false, ldap_servers: [])
  end

  def disable_captcha
    allow(view).to receive_messages(captcha_enabled?: false, captcha_on_login_required?: false)
  end
end
