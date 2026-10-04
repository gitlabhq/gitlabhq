# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineDestroy', :clean_gitlab_redis_rate_limiting, feature_category: :pipeline_composition do
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

  it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_pipeline do
    let(:boundary_object) { project }
    let(:mutation) do
      graphql_mutation(
        :pipeline_destroy,
        { id: pipeline.to_global_id.to_s },
        'errors'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
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

  context 'when the rate limit is exceeded', :freeze_time do
    before do
      stub_application_setting(pipeline_delete_limit_per_user_project: 1)

      ::Ci::DestroyPipelineService.new(project, user).execute(create(:ci_pipeline, project: project))
    end

    it 'surfaces the throttle in errors and does not destroy the pipeline', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: user)

      expect(graphql_mutation_response(:pipeline_destroy)['errors'])
        .to contain_exactly(::Gitlab::ApplicationRateLimiter.throttled_error_message)
      expect(pipeline.reload).to be_persisted
    end
  end
end
