# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInstallation::InstanceService, :enable_admin_mode, :with_current_organization, feature_category: :integrations do
  let_it_be(:user) { create(:admin) }
  let(:params) { {} }

  subject(:service) { described_class.new(current_user: user, params: params) }

  it_behaves_like Integrations::SlackInstallation::BaseService do
    let(:installation_alias) { "gitlab-organization-#{current_organization.id}" }
    let(:integration) { Integrations::GitlabSlackApplication.for_organization(current_organization).first }
    let(:redirect_url) { Gitlab::Routing.url_helpers.slack_auth_admin_application_settings_slack_url }
    let(:enqueues_propagation_worker) { true }
    let(:params) { { code: oauth_code, organization_id: current_organization.id } }

    def create_gitlab_slack_application_integration!
      Integrations::GitlabSlackApplication.create!(instance: true, organization: current_organization)
    end
  end

  it 'finds the integration for the requested organization' do
    stub_application_setting(slack_app_enabled: true)
    other_integration = create(:gitlab_slack_application_integration, :instance,
      organization: create(:organization), slack_integration: build(:slack_integration))
    current_integration = create(:gitlab_slack_application_integration, :instance,
      organization: current_organization, slack_integration: build(:slack_integration))
    requested_service = described_class.new(current_user: user, params: { organization_id: current_organization.id })

    expect(requested_service.send(:find_or_create_integration!)).to eq(current_integration)
    expect(other_integration.reload).to be_persisted
  end
end
