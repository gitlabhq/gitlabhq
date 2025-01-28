# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines.jobs.manualVariables', feature_category: :ci_variables do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipelines {
            nodes {
              jobs {
                nodes {
                  manualVariables {
                    nodes {
                      key
                    }
                  }
                }
              }
            }
          }
        }
      }
    )
  end

  it 'returns the manual variables for actionable jobs' do
    job = create(:ci_build, :actionable, pipeline: pipeline)
    create(:ci_job_variable, key: 'MANUAL_TEST_VAR', job: job)

    post_graphql(query, current_user: user)

    variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
      .dig('jobs', 'nodes').flat_map { |job| job.dig('manualVariables', 'nodes') }
    expect(variables_data.map { |var| var['key'] }).to match_array(['MANUAL_TEST_VAR'])
  end

  it 'does not fetch job variables for jobs that are not actionable' do
    job = create(:ci_build, pipeline: pipeline, status: :manual)
    create(:ci_job_variable, key: 'THIS_VAR_WOULD_SHOULD_NEVER_EXIST', job: job)

    post_graphql(query, current_user: user)

    variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
      .dig('jobs', 'nodes').flat_map { |job| job.dig('manualVariables', 'nodes') }
    expect(variables_data).to be_empty
  end

  it 'does not fetch job variables for bridges' do
    create(:ci_bridge, :manual, pipeline: pipeline)

    post_graphql(query, current_user: user)

    variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
      .dig('jobs', 'nodes').flat_map { |job| job.dig('manualVariables', 'nodes') }
    expect(variables_data).to be_empty
  end

  it 'does not produce N+1 queries', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/367991' do
    second_user = create(:user)
    project.add_maintainer(second_user)
    job = create(:ci_build, :manual, pipeline: pipeline)
    create(:ci_job_variable, key: 'MANUAL_TEST_VAR_1', job: job)

    control_count = ActiveRecord::QueryRecorder.new do
      post_graphql(query, current_user: user)
    end

    variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
      .dig('jobs', 'nodes').flat_map { |job| job.dig('manualVariables', 'nodes') }
    expect(variables_data.map { |var| var['key'] }).to match_array(['MANUAL_TEST_VAR_1'])

    job = create(:ci_build, :manual, pipeline: pipeline)
    create(:ci_job_variable, key: 'MANUAL_TEST_VAR_2', job: job)

    expect do
      post_graphql(query, current_user: second_user)
    end.not_to exceed_query_limit(control_count)

    variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
      .dig('jobs', 'nodes').flat_map { |job| job.dig('manualVariables', 'nodes') }
    expect(variables_data.map { |var| var['key'] }).to match_array(%w[MANUAL_TEST_VAR_1 MANUAL_TEST_VAR_2])
  end
end
