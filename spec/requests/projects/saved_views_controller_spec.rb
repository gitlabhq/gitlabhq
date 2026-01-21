# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects::SavedViews', feature_category: :portfolio_management do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:saved_view) { create(:saved_view) }

  before do
    sign_in(user)
  end

  describe 'GET /:namespace/:project/-/saved_views/:id' do
    it 'renders the work items index page' do
      get namespace_project_saved_view_path(
        namespace_id: project.namespace.full_path,
        project_id: project.path,
        id: saved_view.id
      )

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('id="js-work-items"')
    end
  end
end
