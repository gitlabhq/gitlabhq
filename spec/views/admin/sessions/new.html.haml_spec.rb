# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/sessions/new.html.haml', feature_category: :system_access do
  include RenderedHtml

  let(:user) { create(:admin) }

  let(:page) { rendered_html }

  before do
    disable_all_signin_methods

    allow(view).to receive(:current_user).and_return(user)
  end

  context 'internal admin user' do
    before do
      allow(view).to receive(:allow_admin_mode_password_authentication_for_web?).and_return(true)
    end

    it 'shows enter password form' do
      render

      expect(rendered).to have_selector('[data-testid="sign-in-form"]')
      expect(rendered).to have_selector('[data-testid="password-field"]')
    end

    it 'warns authentication not possible if password not set' do
      allow(view).to receive(:allow_admin_mode_password_authentication_for_web?).and_return(false)

      render

      expect(rendered).to have_no_selector('[data-testid="sign-in-form"]')
      expect(rendered).to have_content _('No authentication methods configured.')
    end
  end

  context 'omniauth authentication enabled' do
    before do
      allow(view).to receive(:omniauth_enabled?).and_return(true)
      allow(view).to receive(:password_authentication_enabled_for_web?).and_return(true)
    end

    let(:openid_connect_button_action_url) do
      URI(rendered_html.find_button('Openid Connect').ancestor('form')[:action])
    end

    let(:openid_connect_button_action_url_query) { Rack::Utils.parse_query(openid_connect_button_action_url.query) }

    it 'shows omniauth form' do
      render

      expect(rendered).not_to have_content _('No authentication methods configured.')
      within('[data-testid="divider"]') do
        expect(rendered).to have_content(_('or sign in with'))
      end
      expect(rendered).to have_css('.js-oauth-login')
    end

    context 'when step-up auth config is set' do
      let(:oidc_step_up_auth_options) do
        GitlabSettings::Options.new(
          name: "openid_connect",
          step_up_auth: {
            admin_mode: {
              params: {
                claims: { acr_values: 'gold' }
              }
            }
          }
        )
      end

      let(:oidc_step_up_auth_options_without_params) do
        GitlabSettings::Options.new(name: "openid_connect", step_up_auth: { admin_mode: {} })
      end

      before do
        stub_omniauth_setting(enabled: true, providers: [oidc_step_up_auth_options])

        allow(view).to receive(:omniauth_enabled?).and_return(true)
        allow(view).to receive(:auth_providers).and_return(['openid_connect'])
      end

      it 'includes additional params related to step-up auth in form action url' do
        render

        expect(rendered).to have_button('Openid Connect')

        expect(openid_connect_button_action_url).to have_attributes(path: '/users/auth/openid_connect')
        expect(openid_connect_button_action_url_query).to include('claims' => '{"acr_values":"gold"}')
      end

      context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
        end

        it 'does not include additional params related to step-up auth in form action url' do
          render

          expect(rendered).to have_button('Openid Connect')
          expect(openid_connect_button_action_url).to have_attributes(path: '/users/auth/openid_connect', query: nil)
        end
      end
    end
  end

  context 'ldap authentication' do
    let(:user) { create(:omniauth_user, :admin, extern_uid: 'my-uid', provider: 'ldapmain') }
    let(:server) { { provider_name: 'ldapmain', label: 'LDAP' }.with_indifferent_access }

    before do
      enable_ldap
    end

    it 'is shown when enabled' do
      render

      expect(rendered).to have_selector('[data-testid="ldap-tab"]')
      expect(rendered).to have_css('#ldapmain')
      expect(rendered).to have_field(_('Username'))
      expect(rendered).not_to have_content('No authentication methods configured')
    end

    it 'is not shown when LDAP sign in is disabled' do
      disable_ldap_sign_in

      render

      expect(rendered).not_to have_selector('[data-testid="ldap-tab"]')
      expect(rendered).not_to have_field(_('Username'))
      expect(rendered).to have_content('No authentication methods configured')
    end

    def enable_ldap
      allow(view).to receive(:ldap_servers).and_return([server])
      allow(view).to receive(:form_based_providers).and_return([:ldapmain])
      allow(view).to receive(:omniauth_callback_path).with(:user, 'ldapmain').and_return('/ldapmain')
      allow(view).to receive(:ldap_sign_in_enabled?).and_return(true)
    end

    def disable_ldap_sign_in
      allow(view).to receive(:ldap_sign_in_enabled?).and_return(false)
      allow(view).to receive(:ldap_servers).and_return([])
    end
  end

  def disable_all_signin_methods
    allow(view).to receive(:password_authentication_enabled_for_web?).and_return(false)
    allow(view).to receive(:omniauth_enabled?).and_return(false)
    allow(view).to receive(:ldap_sign_in_enabled?).and_return(false)
  end
end
