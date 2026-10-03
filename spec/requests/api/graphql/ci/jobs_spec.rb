# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.jobs', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:build) do
    create(:ci_build, pipeline: pipeline, name: 'my test job', ref: 'HEAD', tag_list: %w[tag1 tag2], runner: runner)
  end

  let(:query) do
    %(
      query {
        jobs {
          nodes {
            id
            #{fields.join(' ')}
          }
        }
      }
    )
  end

  let(:jobs_graphql_data) { graphql_data_at(:jobs, :nodes) }

  let(:fields) do
    %w[commitPath refPath webPath browseArtifactsPath playPath tags runner{id}]
  end

  it 'returns the paths in each job of a pipeline' do
    post_graphql(query, current_user: admin)

    expect(jobs_graphql_data).to contain_exactly(
      a_graphql_entity_for(
        build,
        commit_path: "/#{project.full_path}/-/commit/#{build.sha}",
        ref_path: "/#{project.full_path}/-/commits/HEAD",
        web_path: "/#{project.full_path}/-/jobs/#{build.id}",
        browse_artifacts_path: "/#{project.full_path}/-/jobs/#{build.id}/artifacts/browse",
        play_path: "/#{project.full_path}/-/jobs/#{build.id}/play",
        tags: build.tag_list,
        runner: a_graphql_entity_for(runner)
      )
    )
  end

  context 'when requesting individual fields' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:admin2) { create(:admin) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:pipeline2) { create(:ci_pipeline, project: project2) }

    where(:field) { fields }

    with_them do
      let(:fields) do
        [field]
      end

      it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
        # warm-up cache and so on:
        args = { current_user: admin }
        args2 = { current_user: admin2 }
        post_graphql(query, **args2)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, **args)
        end

        create(:ci_build, pipeline: pipeline2, name: 'my test job2', ref: 'HEAD', tag_list: %w[tag3])
        post_graphql(query, **args)

        expect { post_graphql(query, **args) }.not_to exceed_all_query_limit(control)
      end
    end
  end

  describe '.expandedEnvironmentName' do
    let_it_be(:environment) { create(:environment, project: project, name: 'production') }
    let_it_be(:deploy_job) { create(:ci_build, pipeline: pipeline, name: 'deploy', environment: 'production') }
    let_it_be(:job_environment) do
      create(:job_environment, project: project, environment: environment, pipeline: pipeline, job: deploy_job)
    end

    let(:fields) { ['... on CiJob { expandedEnvironmentName }'] }

    it 'returns the recorded name only for jobs that deploy to an environment' do
      post_graphql(query, current_user: admin)

      expect(jobs_graphql_data).to contain_exactly(
        a_graphql_entity_for(deploy_job, 'expandedEnvironmentName' => 'production'),
        a_graphql_entity_for(build, 'expandedEnvironmentName' => be_nil)
      )
    end

    it 'does not generate N+1 queries as jobs span more projects',
      :request_store, :use_sql_query_cache, :aggregate_failures do
      post_graphql(query, current_user: admin)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: admin)
      end

      2.times { |index| create_deploy_job_in_new_project("staging-#{index}") }

      expect { post_graphql(query, current_user: admin) }.not_to exceed_all_query_limit(control)
      expect(resolved_environment_names).to contain_exactly('production', 'staging-0', 'staging-1')
    end

    def create_deploy_job_in_new_project(environment_name)
      other_project = create(:project)
      other_pipeline = create(:ci_pipeline, project: other_project)

      create(:job_environment,
        project: other_project,
        environment: create(:environment, project: other_project, name: environment_name),
        pipeline: other_pipeline,
        job: create(:ci_build, pipeline: other_pipeline, name: 'deploy', environment: environment_name))
    end

    def resolved_environment_names
      jobs_graphql_data.filter_map { |job| job['expandedEnvironmentName'] }
    end
  end
end

RSpec.describe 'Query.jobs.runner', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }

  let(:jobs_runner_graphql_data) { graphql_data_at(:jobs, :nodes, :runner) }
  let(:query) do
    %(
      query {
        jobs {
          nodes {
            runner{
              id
              adminUrl
              description
            }
          }
        }
      }
    )
  end

  context 'when job has no runner' do
    let_it_be(:build) { create(:ci_build) }

    it 'returns nil' do
      post_graphql(query, current_user: admin)

      expect(jobs_runner_graphql_data).to eq([nil])
    end
  end

  context 'when job has runner' do
    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:build_with_runner) { create(:ci_build, runner: runner) }

    it 'returns runner attributes' do
      post_graphql(query, current_user: admin)

      expect(jobs_runner_graphql_data).to contain_exactly(a_graphql_entity_for(runner, :description, 'adminUrl' => "http://localhost/admin/runners/#{runner.id}"))
    end
  end
end

RSpec.describe 'Query.project.pipeline', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  def all(*fields)
    fields.flat_map { |f| [f, :nodes] }
  end

  describe '.stages.groups.jobs' do
    let(:pipeline) do
      pipeline = create(:ci_pipeline, project: project, user: user)
      stage = create(:ci_stage, project: project, pipeline: pipeline, name: 'first', position: 1)
      create(
        :ci_build, pipeline: pipeline, name: 'my test job',
        scheduling_type: :stage, stage_id: stage.id, stage_idx: stage.position
      )

      pipeline
    end

    let(:jobs_graphql_data) { graphql_data_at(:project, :pipeline, *all(:stages, :groups, :jobs)) }

    let(:first_n) { var('Int') }

    let(:query) do
      with_signature(
        [first_n],
        wrap_fields(
          query_graphql_path(
            [
              [:project, { full_path: project.full_path }],
              [:pipeline, { iid: pipeline.iid.to_s }],
              [:stages,   { first: first_n }]
            ],
            stage_fields
          )
        )
      )
    end

    let(:stage_fields) do
      <<~FIELDS
      nodes {
        name
        groups {
          nodes {
            detailedStatus {
              id
            }
            name
            jobs {
              nodes {
                downstreamPipeline {
                  id
                  path
                }
                name
                needs {
                  nodes { #{all_graphql_fields_for('CiBuildNeed')} }
                }
                previousStageJobsOrNeeds {
                  nodes {
                      ... on CiBuildNeed {
                        name
                      }
                      ... on CiJob {
                        name
                      }
                    }
                }
                detailedStatus {
                  id
                }
                pipeline {
                  id
                }
              }
            }
          }
        }
      }
      FIELDS
    end

    it 'returns the jobs of a pipeline stage' do
      post_graphql(query, current_user: user)

      expect(jobs_graphql_data).to contain_exactly(a_hash_including('name' => 'my test job'))
    end

    context 'when there is more than one stage and job needs' do
      before do
        build_stage = create(:ci_stage, position: 2, name: 'build', project: project, pipeline: pipeline)
        test_stage = create(:ci_stage, position: 3, name: 'test', project: project, pipeline: pipeline)
        deploy_stage = create(:ci_stage, position: 4, name: 'deploy', project: project, pipeline: pipeline)

        create(:ci_build, pipeline: pipeline, name: 'docker 1 2', scheduling_type: :stage, ci_stage: build_stage, stage_idx: build_stage.position)
        create(:ci_build, pipeline: pipeline, name: 'docker 2 2', ci_stage: build_stage, stage_idx: build_stage.position, scheduling_type: :dag)
        create(:ci_build, pipeline: pipeline, name: 'rspec 1 2', scheduling_type: :stage, ci_stage: test_stage, stage_idx: test_stage.position)
        create(:ci_build, pipeline: pipeline, name: 'deploy', scheduling_type: :stage, ci_stage: deploy_stage, stage_idx: deploy_stage.position)
        test_job = create(:ci_build, pipeline: pipeline, name: 'rspec 2 2', scheduling_type: :dag, ci_stage: test_stage, stage_idx: test_stage.position)

        create(:ci_build_need, build: test_job, name: 'my test job')
      end

      it 'reports the build needs and execution requirements' do
        post_graphql(query, current_user: user)

        expect(jobs_graphql_data).to contain_exactly(
          a_hash_including(
            'name' => 'my test job',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => [] }
          ),
          a_hash_including(
            'name' => 'docker 1 2',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => [a_hash_including('name' => 'my test job')] }
          ),
          a_hash_including(
            'name' => 'docker 2 2',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => [] }
          ),
          a_hash_including(
            'name' => 'rspec 1 2',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => an_array_matching([
              a_hash_including('name' => 'docker 1 2'),
              a_hash_including('name' => 'docker 2 2')
            ]) }
          ),
          a_hash_including(
            'name' => 'rspec 2 2',
            'needs' => { 'nodes' => [a_hash_including('name' => 'my test job')] },
            'previousStageJobsOrNeeds' => { 'nodes' => [a_hash_including('name' => 'my test job')] }
          ),
          a_hash_including(
            'name' => 'deploy',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => an_array_matching([
              a_hash_including('name' => 'rspec 1 2'),
              a_hash_including('name' => 'rspec 2 2')
            ]) }
          )
        )
      end

      it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
        create(:ci_bridge, name: 'bridge-1', pipeline: pipeline, downstream_pipeline: create(:ci_pipeline))

        post_graphql(query, current_user: user)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: user)
        end

        create(:ci_build, name: 'test-a', pipeline: pipeline)
        create(:ci_build, name: 'test-b', pipeline: pipeline)
        create(:ci_bridge, name: 'bridge-2', pipeline: pipeline, downstream_pipeline: create(:ci_pipeline))
        create(:ci_bridge, name: 'bridge-3', pipeline: pipeline, downstream_pipeline: create(:ci_pipeline))

        expect do
          post_graphql(query, current_user: user)
        end.to issue_same_number_of_queries_as(control)
      end
    end
  end

  describe '.jobs.kind' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              stages {
                nodes {
                  groups{
                    nodes {
                      jobs {
                        nodes {
                          kind
                        }
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

    context 'when the job is a build' do
      it 'returns BUILD' do
        create(:ci_build, pipeline: pipeline)

        post_graphql(query, current_user: user)

        job_data = graphql_data_at(:project, :pipeline, :stages, :nodes, :groups, :nodes, :jobs, :nodes).first
        expect(job_data['kind']).to eq 'BUILD'
      end
    end

    context 'when the job is a bridge' do
      it 'returns BRIDGE' do
        create(:ci_bridge, pipeline: pipeline)

        post_graphql(query, current_user: user)

        job_data = graphql_data_at(:project, :pipeline, :stages, :nodes, :groups, :nodes, :jobs, :nodes).first
        expect(job_data['kind']).to eq 'BRIDGE'
      end
    end
  end

  describe '.jobs.artifacts' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              stages {
                nodes {
                  groups{
                    nodes {
                      jobs {
                        nodes {
                          artifacts {
                            nodes {
                              downloadPath
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
        }
      )
    end

    context 'when the job is a build' do
      it "returns the build's artifacts" do
        create(:ci_build, :artifacts, pipeline: pipeline)

        post_graphql(query, current_user: user)

        job_data = graphql_data_at(:project, :pipeline, :stages, :nodes, :groups, :nodes, :jobs, :nodes).first
        expect(job_data.dig('artifacts', 'nodes').count).to be(2)
      end
    end

    context 'when the job is not a build' do
      it 'returns nil' do
        create(:ci_bridge, pipeline: pipeline)

        post_graphql(query, current_user: user)

        job_data = graphql_data_at(:project, :pipeline, :stages, :nodes, :groups, :nodes, :jobs, :nodes).first
        expect(job_data['artifacts']).to be_nil
      end
    end

    context 'with builds and a bridge in the same pipeline', :request_store, :use_sql_query_cache do
      it 'batches artifacts and their download paths without an N+1' do
        create(:ci_build, :artifacts, pipeline: pipeline)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: user)
        end

        create(:ci_build, :artifacts, pipeline: pipeline)
        create(:ci_bridge, pipeline: pipeline)

        expect do
          post_graphql(query, current_user: user)
        end.not_to exceed_all_query_limit(control)
      end
    end
  end

  describe '.jobs.runnerManager' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:runner_manager) { create(:ci_runner_machine, created_at: Time.current, contacted_at: Time.current) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:build) do
      create(:ci_build, pipeline: pipeline, name: 'my test job', runner_manager: runner_manager)
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              jobs {
                nodes {
                  id
                  name
                  runnerManager {
                    #{all_graphql_fields_for('CiRunnerManager', excluded: [:runner], max_depth: 1)}
                  }
                }
              }
            }
          }
        }
      )
    end

    let(:jobs_graphql_data) { graphql_data_at(:project, :pipeline, :jobs, :nodes) }

    it 'returns the runner manager in each job of a pipeline' do
      post_graphql(query, current_user: admin)

      expect(jobs_graphql_data).to contain_exactly(
        a_graphql_entity_for(
          build,
          name: build.name,
          runner_manager: a_graphql_entity_for(
            runner_manager,
            system_id: runner_manager.system_xid,
            created_at: runner_manager.created_at.iso8601,
            contacted_at: runner_manager.contacted_at.iso8601,
            status: runner_manager.status.to_s.upcase
          )
        )
      )
    end

    it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: admin)
      end

      runner_manager2 = create(:ci_runner_machine)
      create(:ci_build, pipeline: pipeline, name: 'my test job2', runner_manager: runner_manager2)

      expect { post_graphql(query, current_user: admin) }.not_to exceed_all_query_limit(control)
    end
  end

  describe '.jobs policy checks for deployment jobs' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:maintainer) { create(:user, maintainer_of: project) }
    let_it_be(:environment) { create(:environment, project: project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: maintainer, sha: project.commit.sha) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              jobs {
                nodes {
                  detailedStatus { action { path } }
                  userPermissions { updateBuild cancelBuild }
                  canPlayJob
                }
              }
            }
          }
        }
      )
    end

    def create_deploy_job(factory = :ci_build)
      create(factory, :running, :deploy_job, :with_deployment, pipeline: pipeline, environment: environment.name)
    end

    it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
      create_deploy_job
      post_graphql(query, current_user: maintainer)

      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: maintainer) }

      3.times { create_deploy_job }

      expect { post_graphql(query, current_user: maintainer) }.not_to exceed_query_limit(control)
      expect(graphql_data_at(:project, :pipeline, :jobs, :nodes).pluck('userPermissions').pluck('cancelBuild')).to eq([true] * 4)
    end

    context 'with the job mix of the pipeline jobs page' do
      # The policy-backed fields of the page. The fields that only read
      # CI-database associations are preloaded by the resolver and covered separately.
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              pipeline(iid: "#{pipeline.iid}") {
                jobs {
                  nodes {
                    detailedStatus { id detailsPath label action { id path } }
                    userPermissions { readBuild updateBuild cancelBuild }
                    canPlayJob playable
                  }
                }
              }
            }
          }
        )
      end

      # Bridges to other projects scale with the page, but the set of downstream
      # projects stays fixed: policy checks cost queries per distinct project.
      let_it_be(:downstream_project) { create(:project, :public, :repository) }
      let_it_be(:manual_downstream_project) { create(:project, :public, :repository) }

      def create_page_jobs
        create(:ci_build, :success, :artifacts, pipeline: pipeline)
        create(:ci_build, :manual, pipeline: pipeline, tag_list: %w[tag1 tag2])
        create(:generic_commit_status, pipeline: pipeline, ref: pipeline.ref)
        create_deploy_job
        create_deploy_job(:ci_bridge)
        create(:ci_build, :manual, :deploy_job, :with_deployment, pipeline: pipeline, environment: environment.name)
        create(:ci_build, :with_deployment, pipeline: pipeline, environment: environment.name,
          options: { environment: { name: environment.name, action: 'stop' } })

        bridge = create(:ci_bridge, :success, pipeline: pipeline)
        create(:ci_sources_pipeline, source_job: bridge, pipeline: create(:ci_pipeline, project: downstream_project))
        create(:ci_bridge, :manual, pipeline: pipeline,
          options: { trigger: { project: manual_downstream_project.full_path } })
      end

      # Cached queries are not counted: expanding a manual bridge's variables for
      # play_job re-issues an identical before_stage lookup per bridge, which the
      # query cache serves and which predates this change.
      it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
        create_page_jobs
        post_graphql(query, current_user: maintainer)

        control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: maintainer) }

        2.times { create_page_jobs }

        expect { post_graphql(query, current_user: maintainer) }.not_to exceed_query_limit(control)
        expect(graphql_data_at(:project, :pipeline, :jobs, :nodes).size).to eq(pipeline.statuses.count)
      end
    end

    # A bridge's detailed status resolves :play_job and :read_pipeline on the
    # downstream pipeline, so it needs the downstream project group and not just
    # deployments. All the bridges here trigger the same project: the policy cost
    # is per distinct project, so only the path resolution scales with the page.
    context 'with the detailed status of manual bridges' do
      let_it_be(:trigger_downstream_project) { create(:project, :public, :repository) }

      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              pipeline(iid: "#{pipeline.iid}") {
                jobs { nodes { detailedStatus { detailsPath action { path } } } }
              }
            }
          }
        )
      end

      def create_manual_bridge
        create(:ci_bridge, :manual, pipeline: pipeline,
          options: { trigger: { project: trigger_downstream_project.full_path } })
      end

      it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
        create_manual_bridge
        post_graphql(query, current_user: maintainer)

        control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: maintainer) }

        3.times { create_manual_bridge }

        expect { post_graphql(query, current_user: maintainer) }.not_to exceed_query_limit(control)
        expect(graphql_data_at(:project, :pipeline, :jobs, :nodes).size).to eq(pipeline.statuses.count)
      end
    end

    context 'with the preload scope derived from the selection' do
      let_it_be(:deploy_job) do
        create(:ci_build, :running, :deploy_job, :with_deployment, pipeline: pipeline,
          environment: environment.name)
      end

      let_it_be(:bridge_downstream_project) { create(:project, :public, :repository) }
      let_it_be(:manual_bridge) do
        create(:ci_bridge, :manual, pipeline: pipeline,
          options: { trigger: { project: bridge_downstream_project.full_path } })
      end

      def query_for(fields)
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              pipeline(iid: "#{pipeline.iid}") {
                jobs { nodes { #{fields} } }
              }
            }
          }
        )
      end

      def expect_preloaded_with(fields, groups)
        if groups
          expect(::Ci::Preloaders::JobPolicyPreloader).to receive(:new)
            .with(anything, maintainer, **groups).once.and_call_original
        else
          expect(::Ci::Preloaders::JobPolicyPreloader).not_to receive(:new)
        end

        post_graphql(query_for(fields), current_user: maintainer)

        expect(graphql_data_at(:project, :pipeline, :jobs, :nodes)).to be_present
      end

      it 'preloads nothing when no policy field is selected' do
        expect_preloaded_with('id name status', nil)
      end

      it 'preloads nothing for read-only permissions' do
        expect_preloaded_with('userPermissions { readBuild readJobArtifacts }', nil)
      end

      it 'preloads deployments for a write permission' do
        expect_preloaded_with('userPermissions { cancelBuild }',
          { deployments: true, downstream_projects: false })
      end

      it 'preloads downstream projects as well for detailedStatus' do
        expect_preloaded_with('detailedStatus { label }',
          { deployments: true, downstream_projects: true })
      end

      it 'preloads deployments for playable' do
        expect_preloaded_with('playable', { deployments: true, downstream_projects: false })
      end

      # ProjectPolicyPreloader is only reached from the downstream project group.
      it 'leaves downstream projects alone when the selection does not need them' do
        expect(::Preloaders::ProjectPolicyPreloader).not_to receive(:new)

        post_graphql(query_for('playable'), current_user: maintainer)

        expect(graphql_data_at(:project, :pipeline, :jobs, :nodes)).to be_present
      end

      it 'preloads downstream projects as well for canPlayJob' do
        expect_preloaded_with('canPlayJob', { deployments: true, downstream_projects: true })
      end

      it 'unions the groups across the selected fields' do
        expect_preloaded_with('playable canPlayJob',
          { deployments: true, downstream_projects: true })
      end

      context 'when batch_pipeline_job_policy_checks is disabled' do
        before do
          stub_feature_flags(batch_pipeline_job_policy_checks: false)
        end

        it 'preloads nothing' do
          expect_preloaded_with('canPlayJob detailedStatus { label }', nil)
        end
      end

      # The flag has a project actor but the groups are recorded on the query
      # context, which spans every connection in the query.
      context 'when a second project in the same query has the flag off' do
        let_it_be(:other_project) { create(:project, :repository, maintainers: maintainer) }
        let_it_be(:other_pipeline) do
          create(:ci_pipeline, project: other_project, user: maintainer, sha: other_project.commit.sha)
        end

        let_it_be(:other_deploy_job) do
          create(:ci_build, :running, :deploy_job, :with_deployment, pipeline: other_pipeline,
            environment: create(:environment, project: other_project).name)
        end

        let(:multi_project_query) do
          %(
            query {
              enabled: project(fullPath: "#{project.full_path}") {
                pipeline(iid: "#{pipeline.iid}") { jobs { nodes { canPlayJob } } }
              }
              disabled: project(fullPath: "#{other_project.full_path}") {
                pipeline(iid: "#{other_pipeline.iid}") { jobs { nodes { canPlayJob } } }
              }
            }
          )
        end

        before do
          stub_feature_flags(batch_pipeline_job_policy_checks: project)
        end

        it 'preloads only for the project the flag is enabled for' do
          only_enabled_project = an_object_satisfying { |jobs| jobs.map(&:project_id).uniq == [project.id] }

          expect(::Ci::Preloaders::JobPolicyPreloader).to receive(:new)
            .with(only_enabled_project, maintainer, deployments: true, downstream_projects: true)
            .once.and_call_original

          post_graphql(multi_project_query, current_user: maintainer)

          expect(graphql_data_at(:enabled, :pipeline, :jobs, :nodes)).to be_present
          expect(graphql_data_at(:disabled, :pipeline, :jobs, :nodes)).to be_present
        end
      end
    end

    context 'with the policy-backed fields of the pipeline jobs page' do
      let_it_be(:downstream_project) { create(:project, :public, :repository) }
      # The maintainer can trigger this one, so canPlayJob is true only while the
      # preloader resolves the bridge's downstream project correctly.
      let_it_be(:manual_downstream_project) { create(:project, :public, :repository, maintainers: maintainer) }
      let_it_be(:outdated_environment) { create(:environment, project: project, name: 'outdated-env') }

      let_it_be(:successful_build) do
        create(:ci_build, :success, :artifacts, name: 'successful-build', pipeline: pipeline)
      end

      let_it_be(:manual_build) { create(:ci_build, :manual, name: 'manual-build', pipeline: pipeline) }
      let_it_be(:generic_status) { create(:generic_commit_status, name: 'generic-status', pipeline: pipeline) }

      let_it_be(:running_deploy) do
        create(:ci_build, :running, :deploy_job, :with_deployment,
          name: 'running-deploy', pipeline: pipeline, environment: environment.name)
      end

      let_it_be(:manual_deploy) do
        create(:ci_build, :manual, :deploy_job, :with_deployment,
          name: 'manual-deploy', pipeline: pipeline, environment: environment.name)
      end

      # A newer successful deployment to the same environment makes this job's own
      # deployment outdated, which is what prevents its write abilities. The sha must
      # differ: older_than_last_successful_deployment? returns false on a sha match.
      let_it_be(:outdated_deploy) do
        job = create(:ci_build, :running, :deploy_job, :with_deployment,
          name: 'outdated-deploy', pipeline: pipeline, environment: outdated_environment.name)

        create(:deployment, :success, project: project, environment: outdated_environment,
          sha: project.repository.commit('master~1').sha)

        job
      end

      let_it_be(:successful_bridge) do
        bridge = create(:ci_bridge, :success, name: 'successful-bridge', pipeline: pipeline)
        create(:ci_sources_pipeline, source_job: bridge, pipeline: create(:ci_pipeline, project: downstream_project))
        bridge
      end

      let_it_be(:manual_bridge) do
        create(:ci_bridge, :manual, name: 'manual-bridge', pipeline: pipeline,
          options: { trigger: { project: manual_downstream_project.full_path } })
      end

      let_it_be(:page_jobs) do
        [successful_build, manual_build, generic_status, running_deploy,
          manual_deploy, outdated_deploy, successful_bridge, manual_bridge]
      end

      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              pipeline(iid: "#{pipeline.iid}") {
                jobs {
                  nodes {
                    name
                    detailedStatus { label action { path } }
                    userPermissions { readBuild updateBuild cancelBuild }
                    canPlayJob
                    playable
                  }
                }
              }
            }
          }
        )
      end

      # Every policy-backed value the page renders, for one job of each kind the
      # preloader handles. Both flag states are checked against this, so a preload
      # that resolves the wrong environment or downstream project shows up here.
      let(:expected_nodes) do
        {
          'successful-build' => {
            'name' => 'successful-build',
            'detailedStatus' => {
              'label' => 'passed',
              'action' => { 'path' => job_action_path(successful_build, 'retry') }
            },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => false,
            'playable' => false
          },
          'manual-build' => {
            'name' => 'manual-build',
            'detailedStatus' => {
              'label' => 'manual play action',
              'action' => { 'path' => job_action_path(manual_build, 'play') }
            },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => true,
            'playable' => true
          },
          'generic-status' => {
            'name' => 'generic-status',
            'detailedStatus' => { 'label' => 'external commit status', 'action' => nil },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => false,
            'playable' => false
          },
          'running-deploy' => {
            'name' => 'running-deploy',
            'detailedStatus' => {
              'label' => 'running',
              'action' => { 'path' => job_action_path(running_deploy, 'cancel') }
            },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => false,
            'playable' => false
          },
          'manual-deploy' => {
            'name' => 'manual-deploy',
            'detailedStatus' => {
              'label' => 'manual play action',
              'action' => { 'path' => job_action_path(manual_deploy, 'play') }
            },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => true,
            'playable' => true
          },
          # has_outdated_deployment? is what withholds the write abilities here, and it
          # reads the environment's last_deployment that the preloader loads.
          'outdated-deploy' => {
            'name' => 'outdated-deploy',
            'detailedStatus' => { 'label' => 'running', 'action' => nil },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => false, 'cancelBuild' => false },
            'canPlayJob' => false,
            'playable' => false
          },
          'successful-bridge' => {
            'name' => 'successful-bridge',
            'detailedStatus' => {
              'label' => 'passed',
              'action' => { 'path' => job_action_path(successful_bridge, 'retry') }
            },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => false,
            'playable' => false
          },
          'manual-bridge' => {
            'name' => 'manual-bridge',
            'detailedStatus' => {
              'label' => 'manual play action',
              'action' => { 'path' => job_action_path(manual_bridge, 'play') }
            },
            'userPermissions' => { 'readBuild' => true, 'updateBuild' => true, 'cancelBuild' => true },
            'canPlayJob' => true,
            'playable' => true
          }
        }
      end

      def job_action_path(job, action)
        "/#{project.full_path}/-/jobs/#{job.id}/#{action}"
      end

      shared_examples 'the policy-backed fields of the page' do
        it 'returns the expected value for every job' do
          page_jobs

          post_graphql(query, current_user: maintainer)

          expect(graphql_data_at(:project, :pipeline, :jobs, :nodes).index_by { |node| node['name'] })
            .to eq(expected_nodes)
        end
      end

      it_behaves_like 'the policy-backed fields of the page'

      context 'when batch_pipeline_job_policy_checks is disabled' do
        before do
          stub_feature_flags(batch_pipeline_job_policy_checks: false)
        end

        it_behaves_like 'the policy-backed fields of the page'
      end
    end
  end

  describe '.jobs.count' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:successful_job) { create(:ci_build, :success, pipeline: pipeline) }
    let_it_be(:pending_job) { create(:ci_build, :pending, pipeline: pipeline) }
    let_it_be(:failed_job) { create(:ci_build, :failed, pipeline: pipeline) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              jobs {
                count
              }
            }
          }
        }
      )
    end

    before do
      post_graphql(query, current_user: user)
    end

    it 'returns the number of jobs' do
      expect(graphql_data_at(:project, :pipeline, :jobs, :count)).to eq(3)
    end

    context 'with limit value' do
      let(:limit) { 1 }

      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              pipeline(iid: "#{pipeline.iid}") {
                jobs {
                  count(limit: #{limit})
                }
              }
            }
          }
        )
      end

      it 'returns a limited number of jobs' do
        expect(graphql_data_at(:project, :pipeline, :jobs, :count)).to eq(2)
      end

      context 'with invalid value' do
        let(:limit) { 1500 }

        it 'returns a validation error' do
          expect(graphql_errors).to include(a_hash_including('message' => 'limit must be less than or equal to 1000'))
        end
      end
    end

    context 'with jobs filter' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              jobs(statuses: FAILED) {
                count
              }
            }
          }
        )
      end

      it 'returns the number of failed jobs' do
        expect(graphql_data_at(:project, :jobs, :count)).to eq(1)
      end
    end
  end

  context 'when querying jobs for multiple projects' do
    let(:query) do
      %(
        query {
          projects {
            nodes {
              jobs {
                nodes {
                  name
                }
              }
            }
          }
        }
      )
    end

    before do
      create_list(:project, 2).each do |project|
        project.add_developer(user)
        create(:ci_build, project: project)
      end
    end

    it 'returns an error' do
      post_graphql(query, current_user: user)

      expect_graphql_errors_to_include [/"jobs" field can be requested only for 1 Project\(s\) at a time./]
    end
  end

  context 'when batched querying jobs for multiple projects' do
    let(:batched) do
      [
        { query: query_1 },
        { query: query_2 }
      ]
    end

    let(:query_1) do
      %(
        query Page1 {
          projects {
            nodes {
              jobs {
                nodes {
                  name
                }
              }
            }
          }
        }
      )
    end

    let(:query_2) do
      %(
        query Page2 {
          projects {
            nodes {
              jobs {
                nodes {
                  name
                }
              }
            }
          }
        }
      )
    end

    before do
      create_list(:project, 2).each do |project|
        project.add_developer(user)
        create(:ci_build, project: project)
      end
    end

    it 'limits the specific field evaluation per query' do
      get_multiplex(batched, current_user: user)

      resp = json_response

      expect(resp.first.dig('data', 'projects', 'nodes').first.dig('jobs', 'nodes').first['name']).to eq('test')
      expect(resp.first['errors'].first['message'])
        .to match(/"jobs" field can be requested only for 1 Project\(s\) at a time./)
      expect(resp.second.dig('data', 'projects', 'nodes').first.dig('jobs', 'nodes').first['name']).to eq('test')
      expect(resp.second['errors'].first['message'])
        .to match(/"jobs" field can be requested only for 1 Project\(s\) at a time./)
    end
  end
end

RSpec.describe 'previousStageJobs', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:query) do
    <<~QUERY
    {
      project(fullPath: "#{project.full_path}") {
        pipeline(iid: "#{pipeline.iid}") {
          stages {
            nodes {
              groups {
                nodes {
                  jobs {
                    nodes {
                      name
                      previousStageJobs {
                        nodes {
                          name
                          downstreamPipeline {
                            id
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
      }
    }
    QUERY
  end

  it 'does not produce N+1 queries', :request_store, :use_sql_query_cache do
    user1 = create(:user)
    user2 = create(:user)

    create_stage_with_build_and_bridge('build', 0)
    create_stage_with_build_and_bridge('test', 1)

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      post_graphql(query, current_user: user1)
    end

    expect(graphql_data_previous_stage_jobs).to eq(
      'build_build' => [],
      'test_build' => %w[build_build]
    )

    create_stage_with_build_and_bridge('deploy', 2)

    expect do
      post_graphql(query, current_user: user2)
    end.not_to exceed_query_limit(control).allow_skip_cache_inconsistency

    expect(graphql_data_previous_stage_jobs).to eq(
      'build_build' => [],
      'test_build' => %w[build_build],
      'deploy_build' => %w[test_build]
    )
  end

  def create_stage_with_build_and_bridge(stage_name, stage_position)
    stage = create(:ci_stage, position: stage_position, name: "#{stage_name}_stage", project: project, pipeline: pipeline)

    create(:ci_build, pipeline: pipeline, name: "#{stage_name}_build", ci_stage: stage, stage_idx: stage.position)
  end

  def graphql_data_previous_stage_jobs
    stages = graphql_data.dig('project', 'pipeline', 'stages', 'nodes')
    groups = stages.flat_map { |stage| stage.dig('groups', 'nodes') }
    jobs = groups.flat_map { |group| group.dig('jobs', 'nodes') }

    jobs.each_with_object({}) do |job, previous_stage_jobs|
      previous_stage_jobs[job['name']] = job.dig('previousStageJobs', 'nodes').pluck('name')
    end
  end
end
