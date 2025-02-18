# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  around do |example|
    travel_to(Time.current) { example.run }
  end

  describe 'sha' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    let(:pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]).first }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                fullSha: sha
                shortSha: sha(format: SHORT)
                alsoFull: sha(format: LONG)
              }
            }
          }
        }
      )
    end

    it 'returns all formats of the SHA' do
      post_graphql(query, current_user: user)

      expect(pipelines_graphql_data).to include(
        'fullSha' => eq(pipeline.sha),
        'alsoFull' => eq(pipeline.sha),
        'shortSha' => eq(pipeline.short_sha)
      )
    end
  end

  describe 'duration fields' do
    let_it_be(:pipeline) do
      create(:ci_pipeline, project: project)
    end

    let(:query_path) do
      [
        [:project, { full_path: project.full_path }],
        [:pipelines],
        [:nodes]
      ]
    end

    let(:query) do
      wrap_fields(query_graphql_path(query_path, 'queuedDuration duration'))
    end

    before do
      pipeline.update!(
        created_at: 1.minute.ago,
        started_at: 55.seconds.ago
      )
      create(:ci_build, :success, pipeline: pipeline, started_at: 55.seconds.ago, finished_at: 10.seconds.ago)
      pipeline.update_duration
      pipeline.save!

      post_graphql(query, current_user: user)
    end

    it 'includes the duration fields' do
      path = query_path.map(&:first)
      expect(graphql_data_at(*path, :queued_duration)).to eq [5.0]
      expect(graphql_data_at(*path, :duration)).to eq [45]
    end
  end

  describe '.stages' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project) }
    let_it_be(:stage) { create(:ci_stage, pipeline: pipeline, project: project) }
    let_it_be(:other_stage) { create(:ci_stage, pipeline: pipeline, project: project, name: 'other') }

    let(:first_n) { var('Int') }
    let(:query_path) do
      [
        [:project, { full_path: project.full_path }],
        [:pipelines],
        [:nodes],
        [:stages, { first: first_n }],
        [:nodes]
      ]
    end

    let(:query) do
      with_signature([first_n], wrap_fields(query_graphql_path(query_path, :name)))
    end

    before_all do
      # see app/services/ci/ensure_stage_service.rb to explain why we use stage_id
      create(:ci_build, pipeline: pipeline, stage_id: stage.id, name: 'linux: [foo]')
      create(:ci_build, pipeline: pipeline, stage_id: stage.id, name: 'linux: [bar]')
      create(:ci_build, pipeline: pipeline, stage_id: other_stage.id, name: 'linux: [baz]')
    end

    it 'is present if the user has guest access' do
      project.add_guest(user)

      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :pipelines, :nodes, :stages, :nodes, :name))
        .to contain_exactly(eq(stage.name), eq(other_stage.name))
    end

    it 'is present if the user has reporter access' do
      project.add_reporter(user)

      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :pipelines, :nodes, :stages, :nodes, :name))
        .to contain_exactly(eq(stage.name), eq(other_stage.name))
    end

    describe '.groups' do
      let(:query_path) do
        [
          [:project, { full_path: project.full_path }],
          [:pipelines],
          [:nodes],
          [:stages],
          [:nodes],
          [:groups],
          [:nodes]
        ]
      end

      let(:query) do
        wrap_fields(query_graphql_path(query_path, :name))
      end

      it 'is present if the user has guest access' do
        project.add_guest(user)

        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :pipelines, :nodes, :stages, :nodes, :groups, :nodes, :name))
          .to contain_exactly('linux', 'linux')
      end

      it 'is present if the user has reporter access' do
        project.add_reporter(user)

        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :pipelines, :nodes, :stages, :nodes, :groups, :nodes, :name))
          .to contain_exactly('linux', 'linux')
      end
    end
  end

  describe '.job' do
    let(:first_n) { var('Int') }
    let(:query_path) do
      [
        [:project, { full_path: project.full_path }],
        [:pipelines],
        [:nodes],
        [:job, { name: 'Job 1' }]
      ]
    end

    let(:query) do
      wrap_fields(query_graphql_path(query_path, :status))
    end

    before_all do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 1', status: :failed, retried: true)
      create(:ci_build, pipeline: pipeline, name: 'Job 1', status: :success)
    end

    it 'fetches the latest job with the given name' do
      post_graphql(query, current_user: user)
      expect(graphql_data_at(*query_path.map(&:first))).to contain_exactly a_hash_including(
        'status' => 'SUCCESS'
      )
    end
  end

  describe '.jobs' do
    let(:first_n) { var('Int') }
    let(:query_path) do
      [
        [:project, { full_path: project.full_path }],
        [:pipelines, { first: first_n }],
        [:nodes],
        [:jobs],
        [:nodes]
      ]
    end

    let(:query) do
      with_signature([first_n], wrap_fields(query_graphql_path(query_path, :name)))
    end

    before_all do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 1')
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 2')
    end

    it 'limits the results' do
      post_graphql(query, current_user: user, variables: first_n.with(1))

      expect(graphql_data_at(*query_path.map(&:first))).to contain_exactly a_hash_including(
        'name' => 'Job 2'
      )
    end

    it 'fetches all results' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*query_path.map(&:first))).to contain_exactly(
        a_hash_including('name' => 'Job 1'),
        a_hash_including('name' => 'Job 2')
      )
    end

    it 'fetches the jobs without an N+1' do
      first_user = create(:personal_access_token).user
      second_user = create(:personal_access_token).user

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user, variables: first_n.with(1))
      end

      expect do
        post_graphql(query, current_user: second_user)
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe '.job_artifacts' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline_job_1) { create(:ci_build, pipeline: pipeline, name: 'Job 1') }
    let_it_be(:pipeline_job_artifact_1) { create(:ci_job_artifact, job: pipeline_job_1) }
    let_it_be(:pipeline_job_2) { create(:ci_build, pipeline: pipeline, name: 'Job 2') }
    let_it_be(:pipeline_job_artifact_2) { create(:ci_job_artifact, job: pipeline_job_2) }

    let(:path) { %i[project pipelines nodes jobArtifacts] }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                jobArtifacts {
                  name
                  downloadPath
                  fileType
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

    it 'returns the job_artifacts of a pipeline' do
      job_artifacts_graphql_data = graphql_data_at(*path).flatten

      expect(
        job_artifacts_graphql_data.map { |pip| pip['name'] }
      ).to contain_exactly(pipeline_job_artifact_1.filename, pipeline_job_artifact_2.filename)
    end

    it 'avoids N+1 queries' do
      first_user = create(:user)
      second_user = create(:user)

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user)
      end

      pipeline_2 = create(:ci_pipeline, project: project)
      pipeline_2_job_1 = create(:ci_build, pipeline: pipeline_2, name: 'Pipeline 2 Job 1')
      create(:ci_job_artifact, job: pipeline_2_job_1)
      pipeline_2_job_2 = create(:ci_build, pipeline: pipeline_2, name: 'Pipeline 2 Job 2')
      create(:ci_job_artifact, job: pipeline_2_job_2)

      expect do
        post_graphql(query, current_user: second_user)
      end.not_to exceed_query_limit(control_count)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'errorMessages' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:error_message) { create(:ci_pipeline_message, pipeline: pipeline, content: 'error', severity: :error) }

    let(:pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]).first }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                errorMessages {
                  nodes {
                    content
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'returns pipeline errors' do
      post_graphql(query, current_user: user)

      expect(pipelines_graphql_data['errorMessages']['nodes']).to contain_exactly(
        a_hash_including('content' => 'error')
      )
    end

    it 'avoids N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: create(:user))
      end

      pipeline_2 = create(:ci_pipeline, project: project)
      create(:ci_pipeline_message, pipeline: pipeline_2, content: 'error')

      expect do
        post_graphql(query, current_user: create(:user))
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe 'warningMessages' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:warning_message) { create(:ci_pipeline_message, pipeline: pipeline, content: 'warning') }

    let(:pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]).first }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                warningMessages {
                  nodes {
                    content
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'returns pipeline warnings' do
      post_graphql(query, current_user: user)

      expect(pipelines_graphql_data['warningMessages']['nodes']).to contain_exactly(
        a_hash_including('content' => 'warning')
      )
    end

    it 'avoids N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: create(:user))
      end

      pipeline_2 = create(:ci_pipeline, project: project)
      create(:ci_pipeline_message, pipeline: pipeline_2, content: 'warning')

      expect do
        post_graphql(query, current_user: create(:user))
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe '.jobs(securityReportTypes)' do
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                jobs(securityReportTypes: [SAST]) {
                  nodes {
                    name
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'fetches the jobs matching the report type filter' do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, :dast, name: 'DAST Job 1', pipeline: pipeline)
      create(:ci_build, :sast, name: 'SAST Job 1', pipeline: pipeline)

      post_graphql(query, current_user: user)

      expect(response).to have_gitlab_http_status(:ok)

      pipelines_data = graphql_data.dig('project', 'pipelines', 'nodes')

      job_names = pipelines_data.flat_map do |pipeline_data|
        jobs_data = pipeline_data.dig('jobs', 'nodes')
        jobs_data.map { |job_data| job_data['name'] }
      end

      expect(job_names).to contain_exactly('SAST Job 1')
    end
  end

  describe 'upstream' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
    let_it_be(:upstream_project) { create(:project, :repository, :public) }
    let_it_be(:upstream_pipeline) { create(:ci_pipeline, project: upstream_project, user: user) }

    let(:upstream_pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]).first['upstream'] }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                upstream {
                  iid
                }
              }
            }
          }
        }
      )
    end

    before do
      create(:ci_sources_pipeline, source_pipeline: upstream_pipeline, pipeline: pipeline)

      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns the upstream pipeline of a pipeline' do
      expect(upstream_pipelines_graphql_data['iid'].to_i).to eq(upstream_pipeline.iid)
    end

    context 'when fetching the upstream pipeline from the pipeline' do
      it 'avoids N+1 queries' do
        first_user = create(:user)
        second_user = create(:user)

        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: first_user)
        end

        pipeline_2 = create(:ci_pipeline, project: project, user: user)
        upstream_pipeline_2 = create(:ci_pipeline, project: upstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: upstream_pipeline_2, pipeline: pipeline_2)
        pipeline_3 = create(:ci_pipeline, project: project, user: user)
        upstream_pipeline_3 = create(:ci_pipeline, project: upstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: upstream_pipeline_3, pipeline: pipeline_3)

        expect do
          post_graphql(query, current_user: second_user)
        end.not_to exceed_query_limit(control_count)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'downstream' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
    let(:pipeline_2) { create(:ci_pipeline, project: project, user: user) }

    let_it_be(:downstream_project) { create(:project, :repository, :public) }
    let_it_be(:downstream_pipeline_a) { create(:ci_pipeline, project: downstream_project, user: user) }
    let_it_be(:downstream_pipeline_b) { create(:ci_pipeline, project: downstream_project, user: user) }

    let(:pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                downstream {
                  nodes {
                    iid
                  }
                }
              }
            }
          }
        }
      )
    end

    before do
      create(:ci_sources_pipeline, source_pipeline: pipeline, pipeline: downstream_pipeline_a)
      create(:ci_sources_pipeline, source_pipeline: pipeline_2, pipeline: downstream_pipeline_b)

      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns the downstream pipelines of a pipeline' do
      downstream_pipelines_graphql_data = pipelines_graphql_data.flat_map { |pip| pip['downstream']['nodes'] }

      expect(
        downstream_pipelines_graphql_data.map { |pip| pip['iid'].to_i }
      ).to contain_exactly(downstream_pipeline_a.iid, downstream_pipeline_b.iid)
    end

    context 'when fetching the downstream pipelines from the pipeline' do
      it 'avoids N+1 queries' do
        first_user = create(:user)
        second_user = create(:user)

        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: first_user)
        end

        downstream_pipeline_2a = create(:ci_pipeline, project: downstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: pipeline, pipeline: downstream_pipeline_2a)
        downsteam_pipeline_3a = create(:ci_pipeline, project: downstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: pipeline, pipeline: downsteam_pipeline_3a)

        downstream_pipeline_2b = create(:ci_pipeline, project: downstream_project, user: user)
        create(:ci_sources_pipeline, source_pipeline: pipeline_2, pipeline: downstream_pipeline_2b)
        downsteam_pipeline_3b = create(:ci_pipeline, project: downstream_project, user: first_user)
        create(:ci_sources_pipeline, source_pipeline: pipeline_2, pipeline: downsteam_pipeline_3b)

        expect do
          post_graphql(query, current_user: second_user)
        end.not_to exceed_query_limit(control_count)
      end
    end
  end

  describe 'ref_path' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:pipeline_1) { create(:ci_pipeline, project: project, user: user, merge_request: merge_request) }
    let_it_be(:pipeline_2) { create(:ci_pipeline, project: project, user: user, merge_request: merge_request) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                refPath
              }
            }
          }
        }
      )
    end

    it 'avoids N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: user)
      end

      create(:ci_pipeline, project: project, user: user, merge_request: merge_request)

      expect do
        post_graphql(query, current_user: user)
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe 'type' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user, merge_request: merge_request) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                type
              }
            }
          }
        }
      )
    end

    let(:pipelines_graphql_data) { graphql_data.dig(*%w[project pipelines nodes]).first }

    it 'returns the correct pipeline type' do
      post_graphql(query, current_user: user)

      expect(pipelines_graphql_data).to include(
        'type' => eq(pipeline.type)
      )
    end

    it 'avoids N+1 queries' do
      first_user = create(:user)
      second_user = create(:user)

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user)
      end

      create(:ci_pipeline, project: project, merge_request: merge_request)
      create(:ci_pipeline, project: project, merge_request: merge_request)

      expect do
        post_graphql(query, current_user: second_user)
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe 'filtering' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines(updatedAfter: "#{updated_after_arg}", updatedBefore: "#{updated_before_arg}") {
              nodes {
                id
              }}}}
      )
    end

    context 'when filtered by updated_at' do
      let_it_be(:oldish_pipeline) { create(:ci_empty_pipeline, project: project, updated_at: 3.days.ago) }
      let_it_be(:older_pipeline) { create(:ci_empty_pipeline, project: project, updated_at: 10.days.ago) }

      let(:updated_after_arg) { 5.days.ago }
      let(:updated_before_arg) { 1.day.ago }

      before do
        post_graphql(query, current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'accepts filter params' do
        pipeline_ids = graphql_data.dig('project', 'pipelines', 'nodes').map { |pipeline| pipeline.fetch('id') }

        expect(pipeline_ids).to match_array(oldish_pipeline.to_global_id.to_s)
      end
    end
  end
end
