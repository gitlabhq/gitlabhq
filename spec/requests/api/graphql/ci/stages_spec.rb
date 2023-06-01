# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.pipeline.stages', feature_category: :continuous_integration do
  include GraphqlHelpers

  subject(:post_query) { post_graphql(query, current_user: user) }

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:stage_nodes) { graphql_data_at(:project, :pipeline, :stages, :nodes) }
  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('CiStage', max_depth: 2)}
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

  before_all do
    create(:ci_stage, pipeline: pipeline, name: 'deploy')
    create(:ci_build, pipeline: pipeline, stage: 'deploy')
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_query
    end
  end

  it 'returns the stage of a pipeline' do
    post_query

    expect(stage_nodes.first['name']).to eq('deploy')
  end

  describe 'job pagination' do
    let(:job_nodes) { graphql_dig_at(stage_nodes, :jobs, :nodes) }

    it 'returns up to default limit jobs per stage' do
      post_query

      expect(job_nodes.count).to eq(1)
    end

    context 'when the limit is manually set' do
      before do
        stub_application_setting(jobs_per_stage_page_size: 1)
      end

      it 'returns up to custom limit jobs per stage' do
        post_query

        expect(job_nodes.count).to eq(1)
      end
    end
  end
end
