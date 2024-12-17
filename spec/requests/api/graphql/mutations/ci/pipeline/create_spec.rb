# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineCreate', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      **params
    }

    graphql_mutation(
      :pipeline_create,
      variables,
      <<-QL
        errors
        pipeline {
          id
        }
      QL
    )
  end

  let(:params) { { ref: 'master', variables: [] } }

  let(:mutation_response) { graphql_mutation_response(:pipeline_create) }

  it 'returns an error if the user is not allowed to create a pipeline' do
    post_graphql_mutation(mutation, current_user: build(:user))

    expect(graphql_errors.first['message']).to include("you don't have permission to perform this action")
  end

  context 'when the user is authorized' do
    let_it_be(:user) { create(:user) }

    before_all do
      project.add_developer(user)
    end

    context 'when the pipeline creation is not successful' do
      it 'returns error' do
        expect_next_instance_of(::Ci::CreatePipelineService, project, user, params) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Error'))
        end

        post_graphql_mutation(mutation, current_user: user)

        expect(mutation_response['errors']).to include('Error')
        expect(mutation_response['pipeline']).to be_nil
      end
    end

    context 'when the pipeline creation is successful' do
      it 'creates a pipeline' do
        pipeline = create(:ci_pipeline, project: project)

        expect_next_instance_of(::Ci::CreatePipelineService, project, user, params) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success(payload: pipeline))
        end

        post_graphql_mutation(mutation, current_user: user)

        expect(mutation_response['pipeline']['id']).to eq(pipeline.to_global_id.to_s)
        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
