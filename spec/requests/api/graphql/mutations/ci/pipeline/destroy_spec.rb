# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineDestroy', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

  let(:mutation) do
    variables = {
      id: pipeline.to_global_id.to_s
    }
    graphql_mutation(:pipeline_destroy, variables, 'errors')
  end

  it 'returns an error if the user is not allowed to destroy the pipeline' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'destroys a pipeline' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context 'when project is undergoing stats refresh' do
    before do
      create(:project_build_artifacts_size_refresh, :pending, project: pipeline.project)
    end

    it 'returns an error and does not destroy the pipeline' do
      expect(Gitlab::ProjectStatsRefreshConflictsLogger)
        .to receive(:warn_request_rejected_during_stats_refresh)
        .with(pipeline.project.id)

      post_graphql_mutation(mutation, current_user: user)

      expect(graphql_mutation_response(:pipeline_destroy)['errors']).not_to be_empty
      expect(pipeline.reload).to be_persisted
    end
  end
end
