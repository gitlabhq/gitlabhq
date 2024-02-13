# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_tabs_ldap.html.haml', feature_category: :system_access do
  describe 'Crowd form' do
    before do
      stub_devise
      allow(view).to receive(:current_application_settings)
        .and_return(Gitlab::CurrentSettings.current_application_settings)
      allow(view).to receive(:captcha_enabled?).and_return(false)
      allow(view).to receive(:captcha_on_login_required?).and_return(false)
      allow(view).to receive(:experiment_enabled?).and_return(false)
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
      allow(view).to receive(:captcha_enabled?).and_return(false)
      allow(view).to receive(:captcha_on_login_required?).and_return(false)
    end

    it 'renders user_login label' do
      render

      expect(rendered).to have_content(_('Username or primary email'))
    end
  end

  def stub_devise
    allow(view).to receive(:admin_mode).and_return(false)
    allow(view).to receive(:ldap_servers).and_return([])
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  def enable_crowd
    allow(view).to receive(:form_based_providers).and_return([:crowd])
    allow(view).to receive(:crowd_enabled?).and_return(true)
    allow(view).to receive(:omniauth_authorize_path).with(:user, :crowd)
      .and_return('/crowd')
  end
end
