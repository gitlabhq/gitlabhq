# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlanningHierarchy, type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #planning_hierarchy' do
    it 'renders planning hierarchy' do
      stub_feature_flags(work_items_hierarchy: true)

      get project_planning_hierarchy_path(project)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to match(/id="js-work-items-hierarchy"/)
    end

    it 'renders 404 page' do
      stub_feature_flags(work_items_hierarchy: false)

      get project_planning_hierarchy_path(project)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.body).not_to match(/id="js-work-items-hierarchy"/)
    end
  end
end
