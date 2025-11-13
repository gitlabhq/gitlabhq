# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JobRetry', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: user) }
  let_it_be(:sha) { project.repository.commit.sha }
  let_it_be(:pipeline) { create(:ci_pipeline, sha: sha, project: project, user: user) }

  let(:job) { create(:ci_build, :success, pipeline: pipeline, name: 'build') }

  let(:mutation) do
    variables = {
      id: job.to_global_id.to_s
    }
    graphql_mutation(:job_retry, variables,
      <<-QL
                       errors
                       job {
                         id
                       }
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:job_retry) }

  it 'returns an error if the user is not allowed to retry the job' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  context 'when the job is a Ci::Build' do
    it 'retries the build' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      new_job_id = GitlabSchema.object_from_id(mutation_response['job']['id']).sync.id

      new_job = ::Ci::Build.find(new_job_id)
      expect(new_job).not_to be_retried
    end
  end

  context 'when the job is a Ci::Bridge' do
    let(:job) { create(:ci_bridge, :success, pipeline: pipeline, name: 'puente') }

    it 'retries the bridge' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      new_job_id = GitlabSchema.object_from_id(mutation_response['job']['id']).sync.id

      new_job = ::Ci::Bridge.find(new_job_id)
      expect(new_job).not_to be_retried
    end
  end

  context 'when given CI variables' do
    let(:job) { create(:ci_build, :success, :actionable, pipeline: pipeline, name: 'build') }

    let(:mutation) do
      variables = {
        id: job.to_global_id.to_s,
        variables: { key: 'MANUAL_VAR', value: 'test manual var' }
      }

      graphql_mutation(:job_retry, variables,
        <<-QL
                        errors
                        job {
                          id
                        }
        QL
      )
    end

    it 'applies them to a retried manual job' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)

      new_job_id = GitlabSchema.object_from_id(mutation_response['job']['id']).sync.id
      new_job = ::Ci::Build.find(new_job_id)
      expect(new_job.job_variables.count).to be(1)
      expect(new_job.job_variables.first.key).to eq('MANUAL_VAR')
      expect(new_job.job_variables.first.value).to eq('test manual var')
      expect(new_job.job_variables.first.project_id).to eq(project.id)
    end
  end

  context 'when the job is not retryable' do
    let(:job) { create(:ci_build, :retried, pipeline: pipeline) }

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: user)

      expect(mutation_response['job']).to be_nil
      expect(mutation_response['errors']).to match_array(['Job is not retryable'])
    end
  end

  context 'when given job inputs' do
    let(:inputs_spec) do
      {
        'environment' => { 'type' => 'string', 'default' => 'staging', 'options' => %w[staging production] },
        'debug' => { 'type' => 'boolean', 'default' => false }
      }
    end

    let(:job) do
      create(:ci_build, :success, pipeline: pipeline, name: 'build', options: { inputs: inputs_spec })
    end

    let(:mutation) do
      variables = {
        id: job.to_global_id.to_s,
        inputs: [
          { name: 'environment', value: 'production' },
          { name: 'debug', value: true }
        ]
      }

      graphql_mutation(:job_retry, variables,
        <<-QL
                        errors
                        job {
                          id
                        }
      QL
      )
    end

    it 'applies them to the retried job' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['errors']).to be_empty

      new_job_id = GitlabSchema.object_from_id(mutation_response['job']['id']).sync.id
      new_job = ::Ci::Build.find(new_job_id)
      expect(new_job.inputs.count).to be(2)

      environment_input = new_job.inputs.find_by(name: 'environment')
      expect(environment_input.value).to eq('production')
      expect(environment_input.project_id).to eq(project.id)

      debug_input = new_job.inputs.find_by(name: 'debug')
      expect(debug_input.value).to be true
      expect(debug_input.project_id).to eq(project.id)
    end

    context 'when inputs are invalid' do
      let(:mutation) do
        variables = {
          id: job.to_global_id.to_s,
          inputs: [
            { name: 'environment', value: 'development' }
          ]
        }

        graphql_mutation(:job_retry, variables,
          <<-QL
                          errors
                          job {
                            id
                          }
        QL
        )
      end

      it 'returns validation errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['job']).to be_nil
        expect(mutation_response['errors']).to contain_exactly(
          '`environment` input: `development` cannot be used because it is not in the list of allowed options'
        )
      end
    end

    context 'when the ci_job_inputs feature flag is disabled' do
      before do
        stub_feature_flags(ci_job_inputs: false)
      end

      it 'returns an error when inputs are provided' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['job']).to be_nil
        expect(mutation_response['errors']).to eq(['The inputs argument is not available'])
      end
    end
  end
end
