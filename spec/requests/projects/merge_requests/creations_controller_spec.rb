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

    context 'when rapid_diffs_disabled param is present' do
      it 'uses default action' do
        get_diffs(rapid_diffs_disabled: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('data-page="projects:merge_requests:creations:new"')
      end
    end

    it 'uses rapid diffs action' do
      get_diffs

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-rapid-diffs')
    end

    context "when there is an existing MR targeting same branch" do
      before do
        create(:merge_request, source_project: project, source_branch: source_branch, target_branch: target_branch)
      end

      it 'sets flash alert when there is an existing MR targeting same branch' do
        get_diffs

        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET new after a cherry-pick' do
    # A merge commit and a description template have to be created in the
    # repository, so this uses a project of its own.
    let_it_be(:pick_project, freeze: false) { create(:project, :repository) }
    let_it_be(:pick_user, freeze: false) { pick_project.owner }

    let_it_be_with_reload(:picked_merge_request) do
      create(:merge_request, :merged, source_project: pick_project,
        description: 'Description of the picked merge request')
    end

    before_all do
      merge_commit_sha = pick_project.repository.merge(
        pick_user, picked_merge_request.diff_head_sha, picked_merge_request, 'Merge for the spec'
      )
      picked_merge_request.update!(merge_commit_sha: merge_commit_sha)

      # The template the inherited description has to win over.
      pick_project.repository.create_file(
        pick_user, '.gitlab/merge_request_templates/default.md', "## From the template\n",
        message: 'Add default merge request template', branch_name: pick_project.default_branch
      )
    end

    before do
      sign_in(pick_user)
    end

    def get_new(cherry_picked_merge_request_id:)
      get namespace_project_new_merge_request_path(
        namespace_id: pick_project.namespace,
        project_id: pick_project,
        merge_request: { source_branch: 'merge-test', target_branch: 'master' },
        cherry_picked_merge_request_id: cherry_picked_merge_request_id
      )
    end

    it 'prefills the description with the description of the picked merge request' do
      post cherry_pick_project_commit_path(pick_project, picked_merge_request.merge_commit_sha),
        params: {
          start_branch: 'merge-test',
          create_merge_request: '1',
          copy_merge_request_description: 'true'
        }

      follow_redirect!

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('Description of the picked merge request')
      expect(response.body).not_to include('From the template')
    end

    context 'when the id names no merge request' do
      it 'falls back to the template' do
        get_new(cherry_picked_merge_request_id: non_existing_record_id)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('From the template')
      end
    end

    context 'when the user cannot read the merge request the id names' do
      let_it_be(:unreadable_merge_request) do
        create(:merge_request, source_project: create(:project, :repository, :private),
          description: 'Description nobody may read')
      end

      it 'falls back to the template' do
        get_new(cherry_picked_merge_request_id: unreadable_merge_request.id)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to include('Description nobody may read')
        expect(response.body).to include('From the template')
      end
    end
  end
end
