# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/general.html.haml' do
  let(:app_settings) { Gitlab::CurrentSettings.current_application_settings }
  let(:user) { create(:admin) }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'sourcegraph integration' do
    context 'when sourcegraph feature is enabled' do
      it 'show the form' do
        render

        expect(rendered).to have_field('application_setting_sourcegraph_enabled')
      end
    end
  end

  describe 'prompt user about registration features' do
    context 'when service ping is enabled' do
      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      it_behaves_like 'does not render registration features prompt', :application_setting_disabled_repository_size_limit
    end

    context 'with no license and service ping disabled', :without_license do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'renders registration features prompt', :application_setting_disabled_repository_size_limit
    end
  end

  describe 'add license' do
    before do
      render
    end

    it 'does not show the Add License section' do
      expect(rendered).not_to have_css('#js-add-license-toggle')
    end
  end

  describe 'jira connect settings' do
    it 'shows the jira connect settings section' do
      render

      expect(rendered).to have_css('#js-jira_connect-settings')
    end
  end

  describe 'sign-up restrictions' do
    it 'renders js-signup-form tag' do
      render

      expect(rendered).to match 'id="js-signup-form"'
      expect(rendered).to match ' data-minimum-password-length='
    end
  end

  describe 'error tracking integration' do
    context 'with error tracking feature flag enabled' do
      before do
        stub_feature_flags(gitlab_error_tracking: true)

        render
      end

      it 'expects error tracking settings to be available' do
        expect(rendered).to have_field('application_setting_error_tracking_api_url')
      end

      it 'expects display token and reset token to be available' do
        expect(rendered).to have_content(app_settings.error_tracking_access_token)
        expect(rendered).to have_link(
          'Reset error tracking access token',
          href: reset_error_tracking_access_token_admin_application_settings_url
        )
      end
    end

    context 'with error tracking feature flag disabled' do
      it 'expects error tracking settings to not be avaiable' do
        stub_feature_flags(gitlab_error_tracking: false)

        render

        expect(rendered).not_to have_field('application_setting_error_tracking_api_url')
      end
    end
  end

  # for the licensed tests, refer to ee/spec/views/admin/application_settings/general.html.haml_spec.rb
  describe 'instance-level ai-powered settings', :without_license, feature_category: :code_suggestions do
    before do
      allow(::Gitlab).to receive(:org_or_com?).and_return(gitlab_org_or_com?)

      render
    end

    shared_examples 'does not render the form' do
      it 'does not render the form' do
        expect(rendered).not_to have_field('application_setting_instance_level_ai_beta_features_enabled')
      end
    end

    context 'when on .com or .org' do
      let(:gitlab_org_or_com?) { true }

      it_behaves_like 'does not render the form'
    end

    context 'when not on .com and not on .org' do
      let(:gitlab_org_or_com?) { false }

      it_behaves_like 'does not render the form'
    end
  end

  describe 'private profile restrictions', feature_category: :user_management do
    it 'renders correct ce partial' do
      render

      expect(rendered).to render_template('admin/application_settings/_private_profile_restrictions')
    end
  end
end
