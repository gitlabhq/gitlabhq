# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineRetry', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:mutation) do
    variables = {
      id: pipeline.to_global_id.to_s
    }
    graphql_mutation(
      :pipeline_retry,
      variables,
      <<-QL
        errors
        pipeline {
          id
        }
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:pipeline_retry) }

  it 'returns an error if the user is not allowed to retry the pipeline' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'retries a pipeline' do
    pipeline_id = ::Gitlab::GlobalId.build(pipeline, id: pipeline.id).to_s
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['pipeline']['id']).to eq(pipeline_id)
  end
end
