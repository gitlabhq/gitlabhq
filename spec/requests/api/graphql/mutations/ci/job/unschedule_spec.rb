# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JobUnschedule', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:job) { create(:ci_build, :scheduled, pipeline: pipeline, name: 'build') }

  let(:mutation) do
    variables = {
      id: job.to_global_id.to_s
    }
    graphql_mutation(:job_unschedule, variables,
      <<-QL
                       errors
                       job {
                         id
                       }
    QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:job_unschedule) }

  it 'returns an error if the user is not allowed to unschedule the job' do
    project.add_developer(user)

    post_graphql_mutation(mutation, current_user: user)

    expect(graphql_errors).not_to be_empty
    expect(job.reload.status).to eq('scheduled')
  end

  it 'unschedules a job' do
    project.add_maintainer(user)

    job_id = ::Gitlab::GlobalId.build(job, id: job.id).to_s
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['job']['id']).to eq(job_id)
    expect(job.reload.status).to eq('manual')
  end
end
