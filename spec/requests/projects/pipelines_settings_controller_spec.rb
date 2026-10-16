# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesSettingsController, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_auto_devops) { create(:project_auto_devops) }

  let(:project) { project_auto_devops.project }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET show' do
    it 'redirects with 302 status code', :aggregate_failures do
      get project_pipelines_settings_path(project)

      expect(response).to have_gitlab_http_status(:found)
      expect(URI(response.location).path).to eq(project_settings_ci_cd_path(project))
    end
  end
end
