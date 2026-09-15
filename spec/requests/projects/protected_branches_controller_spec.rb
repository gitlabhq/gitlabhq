# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProtectedBranchesController, feature_category: :source_code_management do
  let_it_be_with_reload(:project) { create(:project, :small_repo) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  before do
    sign_in(maintainer)
  end

  describe 'GET #show' do
    let_it_be(:protected_branch) { create(:protected_branch, project: project, name: 'feature') }

    before_all do
      project.repository.add_branch(maintainer, 'feature-a', project.default_branch)
      project.repository.add_branch(maintainer, 'feature-b', project.default_branch)
    end

    def next_page_links
      response.body.scan(/href="([^"]*page_token=[^"]*)"/).flatten
    end

    it 'renders a next page link when the matching branches span more than one page' do
      get project_protected_branch_path(project, protected_branch, per_page: 1)

      expect(response).to have_gitlab_http_status(:ok)
      expect(next_page_links).to be_present
    end

    it 'keeps the sort param in the next page link' do
      get project_protected_branch_path(project, protected_branch, per_page: 1, sort: 'updated_desc')

      expect(response).to have_gitlab_http_status(:ok)
      expect(next_page_links).to be_present
      expect(next_page_links).to all(include('sort=updated_desc'))
    end
  end
end
