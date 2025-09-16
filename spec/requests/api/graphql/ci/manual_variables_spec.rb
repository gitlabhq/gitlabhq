# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines.jobs.manualVariables', feature_category: :pipeline_composition do
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

  context 'when the project is public' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:user) { create(:user) }

    it 'restricts access to developer+ project members' do
      job = create(:ci_build, :manual, pipeline: pipeline)
      create(:ci_job_variable, key: 'MANUAL_TEST_VAR', job: job)

      post_graphql(query, current_user: user)

      variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
        .dig('jobs', 'nodes').first.dig('manualVariables', 'nodes')
      expect(variables_data).to be_nil

      project.add_developer(user)

      post_graphql(query, current_user: user)
      variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
        .dig('jobs', 'nodes').first.dig('manualVariables', 'nodes')
      expect(variables_data.first['key']).to eq('MANUAL_TEST_VAR')
    end
  end

  context 'when the project is internal' do
    let_it_be(:project) { create(:project, :internal) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:user) { create(:user) }

    it 'restricts access to guest+ project members' do
      job = create(:ci_build, :manual, pipeline: pipeline)
      create(:ci_job_variable, key: 'MANUAL_TEST_VAR', job: job)

      project.add_guest(user)

      post_graphql(query, current_user: user)

      variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
        .dig('jobs', 'nodes').first.dig('manualVariables', 'nodes')
      expect(variables_data.first['key']).to eq('MANUAL_TEST_VAR')
    end
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

  it 'does not fetch job variables for generic commit statuses or bridges' do
    create(:generic_commit_status, pipeline: pipeline)
    create(:ci_bridge, :manual, pipeline: pipeline)

    post_graphql(query, current_user: user)

    variables_data = graphql_data.dig('project', 'pipelines', 'nodes').first
      .dig('jobs', 'nodes').flat_map { |job| job.dig('manualVariables', 'nodes') }
    expect(variables_data).to eq([nil, nil])
  end

  it 'does not produce N+1 queries' do
    first_user = create(:user)
    second_user = create(:user)
    project.add_maintainer(first_user)
    project.add_maintainer(second_user)
    job = create(:ci_build, :manual, pipeline: pipeline)
    create(:ci_job_variable, key: 'MANUAL_TEST_VAR_1', job: job)

    control_count = ActiveRecord::QueryRecorder.new do
      post_graphql(query, current_user: first_user)
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
