# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IntegrationsController, :enable_admin_mode, feature_category: :integrations do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #edit' do
    context 'when remove_monitor_metrics is true' do
      before do
        stub_feature_flags(remove_monitor_metrics: true)
      end

      it 'renders a 404 for the prometheus integration' do
        get edit_admin_application_settings_integration_path(:prometheus)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #overrides' do
    let_it_be(:integration) { create(:jira_integration, :instance) }
    let_it_be(:overridden_integration) { create(:jira_integration) }
    let_it_be(:overridden_other_integration) { create(:confluence_integration) }

    let(:overrides_path) { overrides_admin_application_settings_integration_path(integration, format: format) }

    context 'format html' do
      let(:format) { :html }

      it 'renders' do
        get overrides_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('shared/integrations/overrides')
      end
    end

    context 'format json' do
      let(:format) { :json }
      let(:project) { overridden_integration.project }

      it 'returns the project overrides data' do
        get overrides_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to contain_exactly(
          {
            'id' => project.id,
            'avatar_url' => project.avatar_url,
            'full_name' => project.full_name,
            'name' => project.name,
            'full_path' => project_path(project)
          }
        )
      end
    end
  end
end
