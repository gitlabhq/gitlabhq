# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlanningHierarchy, type: :request, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #planning_hierarchy' do
    it 'renders planning hierarchy' do
      get project_planning_hierarchy_path(project)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
