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

      expect(graphql_data['project']).to eq({
        'ciPipelineCreationRequest' => {
          'error' => nil,
          'pipelineId' => nil,
          'status' => 'IN_PROGRESS'
        }
      })
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
