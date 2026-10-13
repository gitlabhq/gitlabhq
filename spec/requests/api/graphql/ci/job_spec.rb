# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines.job(id)', feature_category: :continuous_integration do
  include GraphqlHelpers

  around do |example|
    travel_to(Time.current) { example.run }
  end

  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let_it_be(:prepare_stage) { create(:ci_stage, pipeline: pipeline, project: project, name: 'prepare') }
  let_it_be(:test_stage) { create(:ci_stage, pipeline: pipeline, project: project, name: 'test') }

  let_it_be(:job_1) { create(:ci_build, pipeline: pipeline, stage: 'prepare', name: 'Job 1') }
  let_it_be_with_reload(:job_2) { create(:ci_build, pipeline: pipeline, stage: 'test', name: 'Job 2') }
  let_it_be(:job_3) { create(:ci_build, pipeline: pipeline, stage: 'test', name: 'Job 3') }

  let(:path_to_job) do
    [
      [:project,   { full_path: project.full_path }],
      [:pipelines, { first: 1 }],
      [:nodes,     nil],
      [:job,       { id: global_id_of(job_2) }]
    ]
  end

  let(:query) do
    wrap_fields(query_graphql_path(query_path, all_graphql_fields_for(terminal_type)))
  end

  describe 'scalar fields' do
    let(:path) { [:project, :pipelines, :nodes, 0, :job] }
    let(:query_path) { path_to_job }
    let(:terminal_type) { 'CiJob' }

    it 'retrieves scalar fields' do
      job_2.update!(
        created_at: 40.seconds.ago,
        queued_at: 32.seconds.ago,
        started_at: 30.seconds.ago,
        finished_at: 5.seconds.ago
      )
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_graphql_entity_for(
        job_2, :name, :allow_failure,
        'duration' => 25,
        'kind' => 'BUILD',
        'queuedDuration' => 2.0,
        'status' => job_2.status.upcase,
        'failureMessage' => job_2.present.failure_message
      )
    end

    context 'when fetching by name' do
      before do
        query_path.last[1] = { name: job_2.name }
      end

      it 'retrieves scalar fields' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(*path)).to match a_graphql_entity_for(job_2, :name)
      end
    end
  end

  describe '.detailedStatus' do
    let(:path) { [:project, :pipelines, :nodes, 0, :job, :detailed_status] }
    let(:query_path) { path_to_job + [:detailed_status] }
    let(:terminal_type) { 'DetailedStatus' }

    it 'retrieves detailed status' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_hash_including(
        'text' => 'Pending',
        'label' => 'pending',
        'action' => a_hash_including('buttonTitle' => 'Cancel this job', 'icon' => 'cancel')
      )
    end
  end

  describe '.expandedEnvironmentName' do
    let_it_be(:environment) { create(:environment, project: project, name: 'production') }
    let_it_be(:deploy_job) do
      create(:ci_build, pipeline: pipeline, stage: 'test', name: 'deploy', environment: 'production')
    end

    let_it_be(:job_environment) do
      create(:job_environment, project: project, environment: environment, pipeline: pipeline, job: deploy_job)
    end

    let(:job_id) { global_id_of(deploy_job) }
    let(:path) { [:project, :pipelines, :nodes, 0, :job] }
    let(:query) { job_query_for(project, job_id) }

    def job_query_for(target_project, id)
      wrap_fields(
        query_graphql_path(
          [
            [:project,   { full_path: target_project.full_path }],
            [:pipelines, { first: 1 }],
            [:nodes,     nil],
            [:job,       { id: id }]
          ],
          'id expandedEnvironmentName'
        )
      )
    end

    it 'returns the environment name the job is configured with' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_graphql_entity_for(
        deploy_job, 'expandedEnvironmentName' => 'production'
      )
    end

    context 'when the environment name contains a variable' do
      let_it_be(:dynamic_environment) { create(:environment, project: project, name: 'review/master') }
      let_it_be(:dynamic_job) do
        create(:ci_build, pipeline: pipeline, name: 'review app', environment: 'review/$CI_COMMIT_REF_SLUG')
      end

      let_it_be(:dynamic_job_environment) do
        create(:job_environment,
          project: project, environment: dynamic_environment, pipeline: pipeline, job: dynamic_job)
      end

      let(:job_id) { global_id_of(dynamic_job) }

      it 'returns the expanded name rather than the name declared in the YAML' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(*path, :expandedEnvironmentName)).to eq('review/master')
      end
    end

    context 'when the job declares an environment but has no job_environments record' do
      let_it_be(:orphaned_job) do
        create(:ci_build, pipeline: pipeline, name: 'orphaned deploy', environment: 'staging')
      end

      let(:job_id) { global_id_of(orphaned_job) }

      # Expanding at query time would use current variable values rather than the
      # ones the pipeline was created with, so no name is better than a wrong one.
      it 'returns null rather than expanding the name at query time' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(*path, :expandedEnvironmentName)).to be_nil
      end
    end

    context 'when the job does not declare an environment' do
      let(:job_id) { global_id_of(job_3) }

      it 'returns null' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(*path)).to match a_graphql_entity_for(job_3, 'expandedEnvironmentName' => be_nil)
      end
    end

    context 'when the project hides environments from non-members' do
      let_it_be(:restricted_project) do
        create(:project, :public).tap do |restricted|
          restricted.project_feature.update!(environments_access_level: ProjectFeature::PRIVATE)
        end
      end

      let_it_be(:restricted_pipeline) { create(:ci_pipeline, project: restricted_project) }
      let_it_be(:restricted_job) do
        create(:ci_build, pipeline: restricted_pipeline, name: 'deploy', environment: 'production')
      end

      let_it_be(:restricted_environment) do
        create(:environment, project: restricted_project, name: 'production')
      end

      let_it_be(:restricted_job_environment) do
        create(:job_environment,
          project: restricted_project, environment: restricted_environment,
          pipeline: restricted_pipeline, job: restricted_job)
      end

      let_it_be(:non_member) { create(:user) }
      let_it_be(:member) { create(:user).tap { |u| restricted_project.add_reporter(u) } }

      let(:query) { job_query_for(restricted_project, global_id_of(restricted_job)) }

      it 'returns null to a user who can read the job but not environments' do
        post_graphql(query, current_user: non_member)

        expect(graphql_data_at(*path)).to match a_graphql_entity_for(
          restricted_job, 'expandedEnvironmentName' => be_nil
        )
      end

      it 'returns the name to a member who can read environments' do
        post_graphql(query, current_user: member)

        expect(graphql_data_at(*path, :expandedEnvironmentName)).to eq('production')
      end
    end

    context 'when the job is a generic commit status' do
      let_it_be(:external_job) { create(:generic_commit_status, pipeline: pipeline, name: 'external') }

      let(:job_id) { global_id_of(external_job) }

      it 'returns null rather than erroring', :aggregate_failures do
        post_graphql(query, current_user: user)

        expect(graphql_errors).to be_nil
        expect(graphql_data_at(*path, :expandedEnvironmentName)).to be_nil
      end
    end

    describe 'N+1 queries', :request_store, :use_sql_query_cache do
      let(:jobs_query) do
        wrap_fields(
          query_graphql_path(
            [
              [:project,   { full_path: project.full_path }],
              [:pipelines, { first: 1 }],
              [:nodes,     nil],
              [:jobs,      nil],
              [:nodes,     nil]
            ],
            'id expandedEnvironmentName'
          )
        )
      end

      let(:token) { { personal_access_token: create(:personal_access_token, user: user) } }

      def run_query
        post_graphql(jobs_query, current_user: user, token: token)
      end

      def resolved_names
        graphql_data_at(:project, :pipelines, :nodes, 0, :jobs, :nodes)
          .filter_map { |job| job['expandedEnvironmentName'] }
      end

      it 'avoids N+1 queries for jobs with a job_environments record', :aggregate_failures do
        run_query
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { run_query }

        2.times do |index|
          job = create(:ci_build, pipeline: pipeline, name: "deploy #{index}", environment: "staging-#{index}")
          create(:job_environment,
            project: project,
            environment: create(:environment, project: project, name: "staging-#{index}"),
            pipeline: pipeline,
            job: job)
        end

        expect { run_query }.not_to exceed_all_query_limit(control)
        expect(resolved_names).to contain_exactly('production', 'staging-0', 'staging-1')
      end

      # Jobs without a record must not reach Ci::Deployable#expanded_environment_name,
      # which gathers the job's variables one job at a time.
      it 'avoids N+1 queries for jobs with no job_environments record', :aggregate_failures do
        run_query
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { run_query }

        2.times do |index|
          create(:ci_build,
            pipeline: pipeline, name: "dynamic deploy #{index}", environment: "review/$CI_COMMIT_REF_SLUG-#{index}")
        end

        expect { run_query }.not_to exceed_all_query_limit(control)
        expect(resolved_names).to contain_exactly('production')
      end
    end
  end

  describe '.stage' do
    let(:path) { [:project, :pipelines, :nodes, 0, :job, :stage] }
    let(:query_path) { path_to_job + [:stage] }
    let(:terminal_type) { 'CiStage' }

    it 'returns appropriate data' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_hash_including(
        'name' => test_stage.name,
        'jobs' => a_hash_including(
          'nodes' => contain_exactly(
            a_graphql_entity_for(job_2),
            a_graphql_entity_for(job_3)
          )
        )
      )
    end
  end
end
