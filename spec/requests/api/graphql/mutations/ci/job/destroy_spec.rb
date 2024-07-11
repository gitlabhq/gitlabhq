# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JobArtifactsDestroy', feature_category: :job_artifacts do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:job) { create(:ci_build) }

  let(:mutation) do
    variables = {
      id: job.to_global_id.to_s
    }
    graphql_mutation(:job_artifacts_destroy, variables, <<~FIELDS)
      job {
        name
      }
      destroyedArtifactsCount
      errors
    FIELDS
  end

  before do
    create(:ci_job_artifact, :archive, job: job)
    create(:ci_job_artifact, :junit, job: job)
  end

  it 'returns an error if the user is not allowed to destroy the job artifacts' do
    post_graphql_mutation(mutation, current_user: user)

    expect(graphql_errors).not_to be_empty
    expect(job.reload.job_artifacts.count).to be(2)
  end

  it 'destroys the job artifacts and returns the expected data' do
    job.project.add_maintainer(user)
    expected_data = {
      'jobArtifactsDestroy' => {
        'errors' => [],
        'destroyedArtifactsCount' => 2,
        'job' => {
          'name' => job.name
        }
      }
    }

    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(graphql_data).to eq(expected_data)
    expect(job.reload.job_artifacts.count).to be(0)
  end
end
