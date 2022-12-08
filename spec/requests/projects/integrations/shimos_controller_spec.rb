# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Projects::Integrations::ShimosController, feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:shimo_integration) { create(:shimo_integration, project: project) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'when Shimo integration is inactive' do
      before do
        shimo_integration.update!(active: false)
      end

      it 'returns 404 status' do
        get project_integrations_shimo_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when Shimo integration is active' do
      it 'renders the "show" template' do
        get project_integrations_shimo_path(project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to include shimo_integration.external_wiki_url
      end
    end
  end
end
