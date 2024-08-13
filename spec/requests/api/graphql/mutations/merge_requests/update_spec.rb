# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of an existing merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, :simple, source_project: project) }

  let(:input) { { 'iid' => merge_request.iid.to_s, project_path: project.full_path } }
  let(:extra_params) { {} }
  let(:input_params) { input.merge(extra_params) }
  let(:mutation_response) { graphql_mutation_response(:merge_request_update) }
  let(:mutation) do
    # exclude codequalityReportsComparer because it's behind a feature flag
    graphql_mutation(:merge_request_update, input_params, nil, %w[productAnalyticsState codequalityReportsComparer])
  end

  context 'when the user is not allowed to update the merge request' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user has permissions to update the merge request' do
    before_all do
      group.add_developer(current_user)
    end

    it_behaves_like 'updating time estimate' do
      let(:resource) { merge_request }
      let(:mutation_name) { 'mergeRequestUpdate' }
    end

    context 'when updating the description' do
      context 'when the description uses the work item closing pattern', :sidekiq_inline do
        let(:work_item) { create(:work_item, :task, :group_level, namespace: group) }
        let(:extra_params) { { description: "Closes #{Gitlab::UrlBuilder.build(work_item)}" } }

        it 'creates a merge request closing issue record' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { MergeRequestsClosingIssues.count }.by(1)
        end
      end
    end

    context 'when required arguments are missing' do
      let(:input_params) { {} }

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) do
          include(end_with(
            'invalid value for projectPath (Expected value to not be null), iid (Expected value to not be null)'
          ))
        end
      end
    end
  end
end
