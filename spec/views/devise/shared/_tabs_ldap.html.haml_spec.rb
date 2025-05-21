# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_tabs_ldap.html.haml', feature_category: :system_access do
  describe 'Crowd form' do
    before do
      stub_devise
      allow(view).to receive_messages(
        current_application_settings: Gitlab::CurrentSettings.current_application_settings,
        captcha_enabled?: false,
        captcha_on_login_required?: false,
        experiment_enabled?: false
      )
    end

    it 'is shown when Crowd is enabled' do
      enable_crowd

      render

      expect(rendered).to have_selector('#crowd form')
    end

    it 'is not shown when Crowd is disabled' do
      render

      expect(rendered).not_to have_selector('#crowd')
    end
  end

  describe 'Base form' do
    before do
      stub_devise
      allow(view).to receive_messages(
        captcha_enabled?: false,
        captcha_on_login_required?: false
      )
    end

    it 'renders user_login label' do
      render

      expect(rendered).to have_content(_('Username or primary email'))
    end
  end

  def stub_devise
    allow(view).to receive_messages(
      admin_mode: false,
      ldap_servers: [],
      devise_mapping: Devise.mappings[:user],
      resource: spy,
      resource_name: :user
    )
  end

  def enable_crowd
    allow(view).to receive_messages(
      form_based_providers: [:crowd],
      crowd_enabled?: true,
      omniauth_authorize_path: '/crowd'
    )
  end
end
