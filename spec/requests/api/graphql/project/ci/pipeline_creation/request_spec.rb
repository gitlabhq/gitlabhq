# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.ciPipelineCreationRequest', :clean_gitlab_redis_shared_state, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:creation_request) { ::Ci::PipelineCreation::Requests.start_for_project(project) }

  let(:query) do
    <<~GQL
      query {
        project(fullPath: "#{project.full_path}") {
          ciPipelineCreationRequest(requestId: "#{creation_request['id']}") {
            error
            pipelineId
            status
            pipeline {
              id
              iid
            }
          }
        }
      }
    GQL
  end

  context 'when the current user can create pipelines on the project' do
    before_all do
      project.add_developer(user)
    end

    it 'returns information about the pipeline creation request' do
      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'ciPipelineCreationRequest')).to match({
        'error' => nil,
        'pipelineId' => nil,
        'status' => 'IN_PROGRESS',
        'pipeline' => nil
      })
    end

    context 'when pipeline has been created' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      before do
        ::Ci::PipelineCreation::Requests.succeeded(creation_request, pipeline.id)
      end

      it 'returns the pipeline object' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'ciPipelineCreationRequest')).to match({
          'error' => nil,
          'pipelineId' => pipeline.to_global_id.to_s,
          'status' => 'SUCCEEDED',
          'pipeline' => {
            'id' => pipeline.to_global_id.to_s,
            'iid' => pipeline.iid.to_s
          }
        })
      end
    end

    context 'when pipeline creation has failed' do
      let(:error_message) { 'Pipeline creation failed due to invalid configuration' }

      before do
        ::Ci::PipelineCreation::Requests.failed(creation_request, error_message)
      end

      it 'returns the error message' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'ciPipelineCreationRequest')).to match({
          'error' => error_message,
          'pipelineId' => nil,
          'status' => 'FAILED',
          'pipeline' => nil
        })
      end
    end
  end

  context 'when the current user cannot create pipelines on the project' do
    before_all do
      project.add_guest(user)
    end

    it 'returns nil' do
      post_graphql(query, current_user: user)

      expect(graphql_data['project']).to eq({ 'ciPipelineCreationRequest' => nil })
    end
  end
end
