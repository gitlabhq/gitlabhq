# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::SlacksController, feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:redirect_url) do
    edit_project_settings_integration_path(
      project,
      Integrations::GitlabSlackApplication.to_param
    )
  end

  before do
    sign_in(user)
  end

  it_behaves_like Integrations::SlackControllerSettings do
    let(:slack_auth_path) { slack_auth_project_settings_slack_path(project) }
    let(:destroy_path) { project_settings_slack_path(project) }
    let(:service) { Integrations::SlackInstallation::ProjectService }
    let(:propagates_on_destroy) { false }

    def create_integration
      create(:gitlab_slack_application_integration, project: project)
    end
  end

  describe 'PUT update' do
    let_it_be(:integration) { create(:gitlab_slack_application_integration, project: project) }

    let(:new_alias) { 'foo' }

    subject(:put_update) do
      put project_settings_slack_path(project), params: { slack_integration: { alias: new_alias } }
    end

    it 'updates the record' do
      expect { put_update }.to change { integration.reload.slack_integration.alias }.to(new_alias)
      expect(flash[:notice]).to eq('The project alias was updated successfully')
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(redirect_url)
    end

    context 'when alias is invalid' do
      let(:new_alias) { '' }

      it 'does not update the record' do
        expect { put_update }.not_to change { integration.reload.slack_integration.alias }
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('projects/settings/slacks/edit')
      end
    end

    context 'when user is unauthorized' do
      let_it_be(:user) { create(:user) }

      it 'returns not found response' do
        put_update

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
