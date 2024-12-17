# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SlacksController, :enable_admin_mode, feature_category: :integrations do
  let_it_be(:user) { create(:admin) }

  before do
    stub_application_setting(slack_app_enabled: true)
    sign_in(user)
  end

  it_behaves_like Integrations::SlackControllerSettings do
    let(:slack_auth_path) { slack_auth_admin_application_settings_slack_path }
    let(:destroy_path) { admin_application_settings_slack_path }
    let(:service) { Integrations::SlackInstallation::InstanceService }
    let(:propagates_on_destroy) { true }

    let(:redirect_url) do
      edit_admin_application_settings_integration_path(
        Integrations::GitlabSlackApplication.to_param
      )
    end

    def create_integration
      create(:gitlab_slack_application_integration, :instance,
        slack_integration: build(:slack_integration)
      )
    end
  end
end
