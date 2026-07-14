# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::BranchRulesController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  describe 'GET #index' do
    context 'when user is a maintainer' do
      let_it_be(:user) { create(:user, maintainer_of: project) }

      before do
        sign_in(user)
      end

      it 'returns ok' do
        get project_settings_repository_branch_rules_path(project)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when user is a guest' do
      let_it_be(:user) { create(:user, guest_of: project) }

      before do
        sign_in(user)
      end

      it 'returns not_found' do
        get project_settings_repository_branch_rules_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
