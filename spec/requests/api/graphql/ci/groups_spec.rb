# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.pipeline.stages.groups' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let(:group_graphql_data) { graphql_data_at(:project, :pipeline, :stages, :nodes, 0, :groups, :nodes) }

  let_it_be(:ref) { 'master' }
  let_it_be(:job_a) { create(:commit_status, pipeline: pipeline, name: 'rspec 0 2', ref: ref) }
  let_it_be(:job_b) { create(:ci_build, pipeline: pipeline, name: 'rspec 0 1', ref: ref) }
  let_it_be(:job_c) { create(:ci_bridge, pipeline: pipeline, name: 'spinach 0 1', ref: ref) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('CiGroup')}
      }
    QUERY
  end

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            stages {
              nodes {
                groups {
                  #{fields}
                }
              }
            }
          }
        }
      }
    )
  end

  before do
    post_graphql(query, current_user: user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns a array of jobs belonging to a pipeline' do
    expect(group_graphql_data).to contain_exactly(
      a_hash_including('name' => 'rspec',   'size' => 2),
      a_hash_including('name' => 'spinach', 'size' => 1)
    )
  end
end
