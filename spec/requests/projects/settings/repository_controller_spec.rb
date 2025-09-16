# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::RepositoryController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    before do
      allow(Project).to receive(:find_by_full_path).and_return(project)
    end

    it 'renders the show template successfully' do
      get project_settings_repository_path(project)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end

    it 'memoizes tag_names call' do
      expect(project.repository).to receive(:tag_names).once.and_call_original

      get project_settings_repository_path(project)
    end

    it 'memoizes branch_names call' do
      expect(project.repository).to receive(:branch_names).once.and_call_original

      get project_settings_repository_path(project)
    end
  end
end
