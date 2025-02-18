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

    fields = <<-QL
      errors
      #{response_fields}
    QL

    graphql_mutation(:pipeline_create, variables, fields, [], operation_name)
  end

  let(:operation_name) { '' }

  let(:response_fields) do
    <<-QL
      pipeline {
        id
      }
    QL
  end

  let(:params) { { ref: 'master', variables: [{ key: 'key', value: 'value', variable_type: 'ENV_VAR' }] } }

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
        stub_ci_builds_disabled

        post_graphql_mutation(mutation, current_user: user)

        expect(mutation_response['errors']).to include('Pipelines are disabled!')
        expect(mutation_response['pipeline']).to be_nil
      end
    end

    context 'when the pipeline creation is successful' do
      it 'creates a pipeline' do
        stub_ci_pipeline_to_return_yaml_file

        expect do
          post_graphql_mutation(mutation, current_user: user)
        end.to change { ::Ci::Pipeline.count }.by(1)

        created_pipeline = ::Ci::Pipeline.last

        expect(created_pipeline.source).to eq('api')
        expect(mutation_response['pipeline']['id']).to eq(created_pipeline.to_global_id.to_s)
      end
    end

    context 'when the `async` argument is `true`' do
      let(:operation_name) { 'internalPipelineCreate' }
      let(:params) { { ref: project.default_branch, async: true } }

      let(:response_fields) do
        <<-QL
          requestId
        QL
      end

      it 'creates the pipeline in a worker and returns the request ID',
        :clean_gitlab_redis_shared_state, :sidekiq_inline do
        stub_ci_pipeline_to_return_yaml_file

        request_id = SecureRandom.uuid
        allow(SecureRandom).to receive(:uuid).and_return(request_id)

        expect do
          post_graphql_mutation(mutation, current_user: user)
        end.to change { ::Ci::Pipeline.count }.by(1)

        expect(mutation_response['requestId']).to eq(request_id)
        expect(::Ci::PipelineCreation::Requests.get_request(project, request_id)['status']).to eq('succeeded')
        expect(::Ci::Pipeline.last.source).to eq('web')
      end
    end
  end
end
