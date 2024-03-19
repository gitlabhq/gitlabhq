# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInstallation::InstanceService, :enable_admin_mode, feature_category: :integrations do
  let_it_be(:user) { create(:admin) }
  let(:params) { {} }

  subject(:service) { described_class.new(current_user: user, params: params) }

  it_behaves_like Integrations::SlackInstallation::BaseService do
    let(:installation_alias) { '_gitlab-instance' }
    let(:integration) { Integrations::GitlabSlackApplication.for_instance.first }
    let(:redirect_url) { Gitlab::Routing.url_helpers.slack_auth_admin_application_settings_slack_url }
    let(:enqueues_propagation_worker) { true }

    def create_gitlab_slack_application_integration!
      Integrations::GitlabSlackApplication.create!(instance: true)
    end
  end
end
