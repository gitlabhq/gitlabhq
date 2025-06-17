# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting pipeline information nested in a project', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:pipeline_2) { create(:ci_pipeline, project: project, sha: 'sha') }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:build_job) { create(:ci_build, :trace_with_sections, name: 'build-a', pipeline: pipeline, stage_idx: 0, stage: 'build') }
  let_it_be(:failed_build) { create(:ci_build, :failed, name: 'failed-build', pipeline: pipeline, stage_idx: 0, stage: 'build') }
  let_it_be(:bridge) { create(:ci_bridge, name: 'ci-bridge-example', pipeline: pipeline, stage_idx: 0, stage: 'build') }

  let(:path) { %i[project pipeline] }
  let(:pipeline_graphql_data) { graphql_data_at(*path) }
  let(:depth) { 3 }
  let(:excluded) { %w[job project jobs] } # Project is very expensive, due to the number of fields
  let(:fields) { all_graphql_fields_for('Pipeline', excluded: excluded, max_depth: depth) }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:pipeline, { iid: pipeline.iid.to_s }, fields)
    )
  end

  it_behaves_like 'a working graphql query', :use_clean_rails_memory_store_caching, :request_store do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'contains pipeline information' do
    post_graphql(query, current_user: current_user)

    expect(pipeline_graphql_data).not_to be_nil
  end

  it 'contains configSource' do
    post_graphql(query, current_user: current_user)

    expect(pipeline_graphql_data['configSource']).to eq('UNKNOWN_SOURCE')
  end

  context 'when batching' do
    let!(:pipeline2) { successful_pipeline }
    let!(:pipeline3) { successful_pipeline }
    let!(:query) { build_query_to_find_pipeline_shas(pipeline, pipeline2, pipeline3) }

    def successful_pipeline
      create(:ci_pipeline, project: project, user: current_user, builds: [create(:ci_build, :success)])
    end

    it 'executes the finder once' do
      mock = double(Ci::PipelinesFinder)
      opts = { iids: [pipeline.iid, pipeline2.iid, pipeline3.iid].map(&:to_s), sort: :asc }

      expect(Ci::PipelinesFinder).to receive(:new).once.with(project, current_user, opts).and_return(mock)
      expect(mock).to receive(:execute).once.and_return(Ci::Pipeline.none)

      post_graphql(query, current_user: current_user)
    end

    it 'keeps the queries under the threshold' do
      control = ActiveRecord::QueryRecorder.new do
        single_pipeline_query = build_query_to_find_pipeline_shas(pipeline)

        post_graphql(single_pipeline_query, current_user: current_user)
      end

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:success)
        expect do
          post_graphql(query, current_user: current_user)
        end.not_to exceed_query_limit(control)
      end
    end
  end

  context 'when enough data is requested' do
    let(:fields) do
      query_graphql_field(:jobs, nil,
        query_graphql_field(
          :nodes, {},
          all_graphql_fields_for('CiJob', max_depth: 1)
        )
      )
    end

    it 'contains jobs' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(*path, :jobs, :nodes)).to contain_exactly(
        a_graphql_entity_for(
          build_job, :name, :duration,
          'status' => build_job.status.upcase
        ),
        a_graphql_entity_for(
          failed_build,
          'status' => failed_build.status.upcase
        ),
        a_graphql_entity_for(
          bridge,
          'status' => bridge.status.upcase
        )
      )
    end
  end

  context 'when a job has been retried' do
    let_it_be(:retried) do
      create(
        :ci_build,
        :retried,
        name: build_job.name,
        pipeline: pipeline,
        stage_idx: 0,
        stage: build_job.stage_name
      )
    end

    let(:fields) do
      query_graphql_field(:jobs, { retried: retried_argument },
        query_graphql_field(:nodes, {}, "id name duration retried")
      )
    end

    context 'when we filter out retried jobs' do
      let(:retried_argument) { false }

      it 'contains latest jobs' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(*path, :jobs, :nodes)).to include(
          a_graphql_entity_for(build_job, :name, :duration, :retried)
        )

        expect(graphql_data_at(*path, :jobs, :nodes)).not_to include(
          a_graphql_entity_for(retried)
        )
      end
    end

    context 'when we filter to only retried jobs' do
      let(:retried_argument) { true }

      it 'contains only retried jobs' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(*path, :jobs, :nodes)).to contain_exactly(
          a_graphql_entity_for(retried)
        )
      end
    end

    context 'when we pass null explicitly' do
      let(:retried_argument) { nil }

      it 'contains all jobs' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(*path, :jobs, :nodes)).to include(
          a_graphql_entity_for(build_job),
          a_graphql_entity_for(retried)
        )
      end
    end
  end

  context 'when requesting only builds with certain statuses' do
    let(:variables) do
      {
        path: project.full_path,
        pipelineIID: pipeline.iid.to_s,
        status: :FAILED
      }
    end

    let(:query) do
      <<~GQL
      query($path: ID!, $pipelineIID: ID!, $status: CiJobStatus!) {
        project(fullPath: $path) {
          pipeline(iid: $pipelineIID) {
            jobs(statuses: [$status]) {
              nodes { id }
            }
          }
        }
      }
      GQL
    end

    it 'can filter build jobs by status' do
      post_graphql(query, current_user: current_user, variables: variables)

      expect(graphql_data_at(*path, :jobs, :nodes))
        .to contain_exactly(a_graphql_entity_for(failed_build))
    end
  end

  context 'when requesting a specific job' do
    let(:variables) do
      {
        path: project.full_path,
        pipelineIID: pipeline.iid.to_s
      }
    end

    let(:build_fields) do
      all_graphql_fields_for('CiJob', max_depth: 1)
    end

    let(:query) do
      <<~GQL
      query($path: ID!, $pipelineIID: ID!, $jobName: String, $jobID: JobID) {
        project(fullPath: $path) {
          pipeline(iid: $pipelineIID) {
            job(id: $jobID, name: $jobName) {
              #{build_fields}
            }
          }
        }
      }
      GQL
    end

    let(:the_job) do
      a_graphql_entity_for(build_job, :name)
    end

    it 'can request a build by name' do
      vars = variables.merge(jobName: build_job.name)

      post_graphql(query, current_user: current_user, variables: vars)

      expect(graphql_data_at(*path, :job)).to match(the_job)
    end

    it 'can request a build by ID' do
      vars = variables.merge(jobID: global_id_of(build_job))

      post_graphql(query, current_user: current_user, variables: vars)

      expect(graphql_data_at(*path, :job)).to match(the_job)
    end

    context 'when we request nested fields of the build' do
      let_it_be(:needy) { create(:ci_build, :dependent, pipeline: pipeline) }

      let(:build_fields) { 'needs { nodes { name } }' }
      let(:vars) { variables.merge(jobID: global_id_of(needy)) }

      it 'returns the nested data' do
        post_graphql(query, current_user: current_user, variables: vars)

        expect(graphql_data_at(*path, :job, :needs, :nodes)).to contain_exactly(
          a_hash_including('name' => needy.needs.first.name)
        )
      end

      it 'requires a constant number of queries' do
        fst_user = create(:user)
        snd_user = create(:user)
        path = %i[project pipeline job needs nodes name]

        baseline = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: fst_user, variables: vars)
        end

        expect(baseline.count).to be > 0
        dep_names = graphql_dig_at(graphql_data(fresh_response_data), *path)

        deps = create_list(:ci_build, 3, :unique_name, pipeline: pipeline)
        deps.each { |d| create(:ci_build_need, build: needy, name: d.name) }

        expect do
          post_graphql(query, current_user: snd_user, variables: vars)
        end.not_to exceed_query_limit(baseline)

        more_names = graphql_dig_at(graphql_data(fresh_response_data), *path)

        expect(more_names).to include(*dep_names)
        expect(more_names.count).to be > dep_names.count
      end
    end
  end

  context 'when requesting a specific test suite' do
    let_it_be(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }
    let(:suite_name) { 'test' }
    let_it_be(:build_ids) { pipeline.latest_builds.pluck(:id) }

    let(:variables) do
      {
        path: project.full_path,
        pipelineIID: pipeline.iid.to_s
      }
    end

    let(:query) do
      <<~GQL
      query($path: ID!, $pipelineIID: ID!, $buildIds: [ID!]!) {
        project(fullPath: $path) {
          pipeline(iid: $pipelineIID) {
            testSuite(buildIds: $buildIds) {
              name
            }
          }
        }
      }
      GQL
    end

    it 'can request a test suite by an array of build_ids' do
      vars = variables.merge(buildIds: build_ids)

      post_graphql(query, current_user: current_user, variables: vars)

      expect(graphql_data_at(:project, :pipeline, :testSuite, :name)).to eq(suite_name)
    end

    context 'when pipeline has no builds that matches the given build_ids' do
      let_it_be(:build_ids) { [non_existing_record_id] }

      it 'returns nil' do
        vars = variables.merge(buildIds: build_ids)

        post_graphql(query, current_user: current_user, variables: vars)

        expect(graphql_data_at(*path, :test_suite)).to be_nil
      end
    end
  end

  context 'N+1 queries on pipeline jobs.previousStageJobsOrNeeds' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    let(:fields) do
      <<~FIELDS
      stages {
        nodes {
          groups {
            nodes {
              jobs {
                nodes {
                  previousStageJobsOrNeeds {
                    nodes {
                      ... on JobNeedUnion {
                        ... on CiBuildNeed {
                          id
                          name
                        }
                        ... on CiJob {
                          id
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      FIELDS
    end

    it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
      build_stage = create(:ci_stage, position: 1, name: 'build', project: project, pipeline: pipeline)
      test_stage = create(:ci_stage, position: 2, name: 'test', project: project, pipeline: pipeline)

      docker_1_2 = create(:ci_build, pipeline: pipeline, name: 'docker 1 2', ci_stage: build_stage)
      create(:ci_build, pipeline: pipeline, name: 'docker 2 2', ci_stage: build_stage)
      create(:ci_build, pipeline: pipeline, name: 'rspec 1 2', ci_stage: test_stage)
      create(:ci_build, :dependent, needed: docker_1_2, pipeline: pipeline, name: 'rspec 2 2', ci_stage: test_stage)

      # warm up
      post_graphql(query, current_user: current_user)
      expect_graphql_errors_to_be_empty

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      create(:ci_build, name: 'test-a', ci_stage: test_stage, pipeline: pipeline)
      test_b_job = create(:ci_build, name: 'test-b', ci_stage: test_stage, pipeline: pipeline)
      create(:ci_build, :dependent, needed: test_b_job, pipeline: pipeline, name: 'docker 2 2', ci_stage: test_stage)

      expect do
        post_graphql(query, current_user: current_user)
      end.not_to exceed_all_query_limit(control)
    end
  end

  context 'N+1 queries on stages jobs' do
    let(:depth) { 5 }
    let(:fields) do
      <<~FIELDS
      stages {
        nodes {
          name
          groups {
            nodes {
              name
              jobs {
                nodes {
                  name
                  needs {
                    nodes {
                      name
                    }
                  }
                  status: detailedStatus {
                    tooltip
                    hasDetails
                    detailsPath
                    action {
                      buttonTitle
                      path
                      title
                      confirmationMessage
                    }
                  }
                }
              }
            }
          }
        }
      }
      FIELDS
    end

    it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
      # create extra statuses
      external_stage = create(:ci_stage, position: 10, name: 'external', project: project, pipeline: pipeline)
      create(:generic_commit_status, :pending, name: 'generic-build-a', pipeline: pipeline, ci_stage: external_stage)
      create(:ci_bridge, :failed, name: 'deploy-a', pipeline: pipeline, stage_idx: 2, stage: 'deploy')

      # warm up
      post_graphql(query, current_user: current_user)
      expect_graphql_errors_to_be_empty

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      create(:generic_commit_status, :pending, name: 'generic-build-b', pipeline: pipeline, ci_stage: external_stage)
      create(:ci_build, :failed, name: 'test-a', pipeline: pipeline, stage_idx: 1, stage: 'test')
      create(:ci_build, :running, name: 'test-b', pipeline: pipeline, stage_idx: 1, stage: 'test')
      create(:ci_build, :pending, name: 'deploy-b', pipeline: pipeline, stage_idx: 2, stage: 'deploy')
      create(:ci_bridge, :failed, name: 'deploy-c', pipeline: pipeline, stage_idx: 2, stage: 'deploy')

      expect do
        post_graphql(query, current_user: current_user)
      end.not_to exceed_all_query_limit(control)
    end
  end

  context 'when no arguments are passed' do
    let(:variables) do
      {
        path: project.full_path
      }
    end

    let(:query) do
      <<~GQL
      query($path: ID!) {
        project(fullPath: $path) {
          pipeline {
            id
          }
        }
      }
      GQL
    end

    it 'returns latest pipeline' do
      post_graphql(query, current_user: current_user, variables: variables)

      expect(graphql_data_at(:project, :pipeline, :id)).to eq(pipeline.to_global_id.to_s)
    end
  end

  context 'when sha argument is passed' do
    let(:variables) do
      {
        path: project.full_path,
        sha: 'sha'
      }
    end

    let(:query) do
      <<~GQL
      query($path: ID!, $sha: String!) {
        project(fullPath: $path) {
          pipeline(sha: $sha) {
            id
          }
        }
      }
      GQL
    end

    it 'returns pipeline by sha' do
      post_graphql(query, current_user: current_user, variables: variables)

      expect(graphql_data_at(:project, :pipeline, :id)).to eq(pipeline_2.to_global_id.to_s)
    end
  end

  private

  def build_query_to_find_pipeline_shas(*pipelines)
    pipeline_fields = pipelines.map.each_with_index do |pipeline, idx|
      "pipeline#{idx}: pipeline(iid: \"#{pipeline.iid}\") { sha }"
    end.join(' ')

    graphql_query_for('project', { 'fullPath' => project.full_path }, pipeline_fields)
  end
end
