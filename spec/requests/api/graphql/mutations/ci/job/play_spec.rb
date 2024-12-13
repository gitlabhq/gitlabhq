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
  end

  context 'with a bridge' do
    let_it_be(:job) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: project, name: 'bridge') }

    include_examples 'playing a job'
  end
end
