# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.jobs', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project, :repository, :public) }
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

  let_it_be(:project) { create(:project, :repository, :public) }
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
        end.not_to exceed_all_query_limit(control)
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
    end.not_to exceed_query_limit(control)

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
