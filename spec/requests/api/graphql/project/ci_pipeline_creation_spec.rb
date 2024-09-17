# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.ciPipelineCreation', :use_clean_rails_redis_caching, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline_creation_id) { SecureRandom.uuid }

  let(:query) do
    <<~QUERY
    {
      project(fullPath: "#{project.full_path}") {
        ciPipelineCreation(id: "#{pipeline_creation_id}") {
          status
          pipelineId
        }
      }
    }
    QUERY
  end

  context 'when the user can read pipelines on the project' do
    before_all do
      project.add_developer(user)
    end

    before do
      Rails.cache.write("project:{#{project.full_path}}:ci_pipeline_creation:{#{pipeline_creation_id}}",
        { status: :creating, pipeline_id: nil })
    end

    it 'returns the status and pieplineID for the pipeline creation' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at('project', 'ciPipelineCreation', 'status')).to eq('CREATING')
    end
  end

  context 'when the user cannot read pipelines on the project' do
    it 'returns null' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at('project', 'ciPipelineCreation')).to be_nil
    end
  end
end
