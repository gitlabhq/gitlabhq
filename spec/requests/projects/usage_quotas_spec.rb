# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Usage Quotas', feature_category: :consumables_cost_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:role) { :maintainer }
  let_it_be(:user) { create(:user) }

  before do
    project.add_role(user, role)
    login_as(user)
  end

  shared_examples 'response with 404 status' do
    it 'renders :not_found' do
      get project_usage_quotas_path(project)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.body).not_to include(project_usage_quotas_path(project))
    end
  end

  describe 'GET /:namespace/:project/usage_quotas' do
    it 'renders usage quotas path' do
      get project_usage_quotas_path(project)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(project_usage_quotas_path(project))
      expect(response.body).to include("Usage of project resources across the <strong>#{project.name}</strong> project")
    end

    context 'renders :not_found for user without permission' do
      let(:role) { :developer }

      it_behaves_like 'response with 404 status'
    end
  end
end
