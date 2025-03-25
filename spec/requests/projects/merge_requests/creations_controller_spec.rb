# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Request Creation', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:source_branch) { 'fix' }
  let_it_be(:target_branch) { 'master' }

  before do
    sign_in(user)
  end

  describe 'GET rapid_diffs' do
    def get_diffs(**extra_params)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        merge_request: {
          source_branch: source_branch,
          target_branch: target_branch
        }
      }

      get namespace_project_new_merge_request_diffs_path(params.merge(extra_params))
    end

    context 'when the feature flag rapid_diffs is disabled' do
      before do
        stub_feature_flags(rapid_diffs: false)
      end

      it 'returns 404' do
        get_diffs(rapid_diffs: 'true')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'does not use rapid diffs action when rapid_diffs flag is false' do
      get_diffs(rapid_diffs: 'false')

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-page="projects:merge_requests:creations:new"')
    end

    it 'uses rapid diffs action when rapid_diffs flag is true' do
      get_diffs(rapid_diffs: 'true')

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-page="projects:merge_requests:creations:rapid_diffs"')
    end

    it 'sets flash alert when there is an existing MR targeting same branch' do
      create(:merge_request, source_project: project, source_branch: source_branch, target_branch: target_branch)
      get_diffs(rapid_diffs: 'true')

      expect(flash[:alert]).to be_present
    end

    it 'assigns show_whitespace_default' do
      get_diffs(rapid_diffs: 'true')

      expect(assigns(:show_whitespace_default)).to be(true)
    end
  end
end
