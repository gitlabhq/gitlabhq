# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineCancel' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:mutation) do
    variables = {
      id: pipeline.to_global_id.to_s
    }
    graphql_mutation(:pipeline_cancel, variables, 'errors')
  end

  let(:mutation_response) { graphql_mutation_response(:pipeline_cancel) }

  before_all do
    project.add_maintainer(user)
  end

  it 'does not cancel any pipelines not owned by the current user' do
    build = create(:ci_build, :running, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
    expect(build).not_to be_canceled
  end

  it 'returns a error if the pipline cannot be be canceled' do
    build = create(:ci_build, :success, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: user)

    expect(mutation_response).to include('errors' => include(eq 'Pipeline is not cancelable'))
    expect(build).not_to be_canceled
  end

  it "cancels all cancelable builds from a pipeline" do
    build = create(:ci_build, :running, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(build.reload).to be_canceled
  end
end
