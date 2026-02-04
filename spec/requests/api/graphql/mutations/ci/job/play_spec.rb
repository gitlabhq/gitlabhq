# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JobPlay', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, maintainers: user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:variables) do
    {
      id: job.to_global_id.to_s
    }
  end

  let(:mutation) do
    graphql_mutation(:job_play, variables,
      <<-QL
                       errors
                       job {
                         id
                         manualVariables {
                           nodes {
                             key
                           }
                         }
                       }
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:job_play) }

  before do
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
  end

  shared_examples 'playing a job' do
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

  context 'with a build' do
    let_it_be(:job) { create(:ci_build, :playable, pipeline: pipeline, name: 'build') }

    include_examples 'playing a job'

    context 'when given variables' do
      let(:variables) do
        {
          id: job.to_global_id.to_s,
          variables: [
            { key: 'MANUAL_VAR_1', value: 'test var' },
            { key: 'MANUAL_VAR_2', value: 'test var 2' }
          ]
        }
      end

      it 'provides those variables to the job', :aggregate_failures do
        expect_next_instance_of(Ci::PlayBuildService) do |instance|
          expect(instance).to receive(:execute).and_call_original
        end

        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['job']['manualVariables']['nodes'].pluck('key')).to contain_exactly(
          'MANUAL_VAR_1', 'MANUAL_VAR_2'
        )
      end
    end

    context 'when given inputs' do
      let_it_be(:job) do
        create(:ci_build, :playable, pipeline: pipeline, name: 'build', options: {
          inputs: {
            environment: { type: 'string' },
            version: { type: 'string', default: '1.0' }
          }
        })
      end

      let(:variables) do
        {
          id: job.to_global_id.to_s,
          inputs: [
            { name: 'environment', value: 'production' }
          ]
        }
      end

      it 'applies those inputs to the job' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(job.reload.inputs.map(&:name)).to contain_exactly('environment')
        expect(job.reload.inputs.find_by(name: 'environment').value).to eq('production')
      end
    end

    context 'when given invalid inputs' do
      let_it_be(:job) do
        create(:ci_build, :playable, pipeline: pipeline, name: 'build', options: {
          inputs: {
            environment: { type: 'string' }
          }
        })
      end

      let(:variables) do
        {
          id: job.to_global_id.to_s,
          inputs: [
            { name: 'unknown_input', value: 'value' }
          ]
        }
      end

      it 'returns an error and does not play the job' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to include(match(/Unknown input/))
        expect(mutation_response['job']).to be_nil
        expect(job.reload).to be_manual
      end
    end

    context 'when inputs feature flag is disabled' do
      let_it_be(:job) do
        create(:ci_build, :playable, pipeline: pipeline, name: 'build', options: {
          inputs: {
            environment: { type: 'string' }
          }
        })
      end

      let(:variables) do
        {
          id: job.to_global_id.to_s,
          inputs: [
            { name: 'environment', value: 'production' }
          ]
        }
      end

      before do
        stub_feature_flags(ci_job_inputs: false)
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to include('The inputs argument is not available')
        expect(mutation_response['job']).to be_nil
      end
    end
  end

  context 'with a bridge' do
    let_it_be(:job) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: project, name: 'bridge') }

    include_examples 'playing a job'
  end
end
