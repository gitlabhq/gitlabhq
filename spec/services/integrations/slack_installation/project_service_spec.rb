# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInstallation::ProjectService, feature_category: :integrations do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let(:params) { {} }

  subject(:service) { described_class.new(project, current_user: user, params: params) }

  it_behaves_like Integrations::SlackInstallation::BaseService do
    let(:installation_alias) { project.full_path }
    let(:integration) { project.gitlab_slack_application_integration }
    let(:redirect_url) { Gitlab::Routing.url_helpers.slack_auth_project_settings_slack_url(project) }
    let(:enqueues_propagation_worker) { false }

    def create_gitlab_slack_application_integration!
      project.create_gitlab_slack_application_integration!
    end
  end
end
