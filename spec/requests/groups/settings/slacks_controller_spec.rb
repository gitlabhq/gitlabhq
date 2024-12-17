# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::SlacksController, feature_category: :integrations do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  before do
    sign_in(user)
    stub_application_setting(slack_app_enabled: true)
  end

  it_behaves_like Integrations::SlackControllerSettings do
    let(:slack_auth_path) { slack_auth_group_settings_slack_path(group) }
    let(:destroy_path) { group_settings_slack_path(group) }
    let(:service) { Integrations::SlackInstallation::GroupService }
    let(:propagates_on_destroy) { true }

    let(:redirect_url) do
      edit_group_settings_integration_path(
        group,
        Integrations::GitlabSlackApplication.to_param
      )
    end

    def create_integration
      create(:gitlab_slack_application_integration, :group, group: group,
        slack_integration: build(:slack_integration)
      )
    end
  end
end
