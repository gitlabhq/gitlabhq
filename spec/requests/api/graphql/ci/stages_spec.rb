# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.pipeline.stages' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let(:stage_graphql_data) { graphql_data['project']['pipeline']['stages'] }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('CiStage')}
      }
    QUERY
  end

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            stages {
              #{fields}
            }
          }
        }
      }
    )
  end

  before do
    create(:ci_stage_entity, pipeline: pipeline, name: 'deploy')
    post_graphql(query, current_user: user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns the stage of a pipeline' do
    expect(stage_graphql_data['nodes'].first['name']).to eq('deploy')
  end
end
