# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_developer(developer) } }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let(:input) do
    {
      project_path: project.full_path,
      title: title,
      source_branch: source_branch,
      target_branch: target_branch
    }
  end

  let(:title) { 'MergeRequest' }
  let(:source_branch) { 'new_branch' }
  let(:target_branch) { 'master' }
  let(:extra_params) { {} }
  let(:current_user) { user }

  let(:mutation) { graphql_mutation(:merge_request_create, input.merge(extra_params)) }
  let(:mutation_response) { graphql_mutation_response(:merge_request_create) }

  context 'the user is not allowed to create a branch' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a merge request' do
    let(:current_user) { developer }

    it 'creates a new merge request' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['mergeRequest']).to include(
        'title' => title
      )
    end

    context 'when the description uses the work item closing pattern', :sidekiq_inline do
      let(:work_item) { create(:work_item, :task, :group_level, namespace: group) }
      let(:extra_params) { { description: "Closes #{Gitlab::UrlBuilder.build(work_item)}" } }

      it 'creates a merge request closing issue record' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { MergeRequestsClosingIssues.count }.by(1)
      end
    end

    context 'when source branch is equal to the target branch' do
      let(:source_branch) { target_branch }

      it_behaves_like 'a mutation that returns errors in the response',
        errors: ['Branch conflict You can\'t use same project/branch for source and target']
    end
  end
end
