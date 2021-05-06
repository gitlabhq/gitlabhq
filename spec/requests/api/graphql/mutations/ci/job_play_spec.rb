# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JobPlay' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:job) { create(:ci_build, pipeline: pipeline, name: 'build') }

  let(:mutation) do
    variables = {
      id: job.to_global_id.to_s
    }
    graphql_mutation(:job_play, variables,
                     <<-QL
                       errors
                       job {
                         id
                       }
                     QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:job_play) }

  before_all do
    project.add_maintainer(user)
  end

  it 'returns an error if the user is not allowed to play the job' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'plays a job' do
    job_id = ::Gitlab::GlobalId.build(job, id: job.id).to_s
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['job']['id']).to eq(job_id)
  end
end
