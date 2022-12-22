# frozen_string_literal: true
require 'spec_helper'

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
      create(:ci_build, stage_id: stage.id, pipeline: pipeline, name: 'my test job', scheduling_type: :stage)

      pipeline
    end

    let(:jobs_graphql_data) { graphql_data_at(:project, :pipeline, *all(:stages, :groups, :jobs)) }

    let(:first_n) { var('Int') }

    let(:query) do
      with_signature([first_n], wrap_fields(query_graphql_path(
                                              [
                                                [:project, { full_path: project.full_path }],
                                                [:pipeline, { iid: pipeline.iid.to_s }],
                                                [:stages,   { first: first_n }]
                                              ], stage_fields)))
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
                        #{all_graphql_fields_for('CiBuildNeed')}
                      }
                      ... on CiJob {
                        #{all_graphql_fields_for('CiJob')}
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

        create(:ci_build, pipeline: pipeline, name: 'docker 1 2', scheduling_type: :stage, ci_stage: build_stage, stage_idx: build_stage.position)
        create(:ci_build, pipeline: pipeline, name: 'docker 2 2', ci_stage: build_stage, stage_idx: build_stage.position, scheduling_type: :dag)
        create(:ci_build, pipeline: pipeline, name: 'rspec 1 2', scheduling_type: :stage, ci_stage: test_stage, stage_idx: test_stage.position)
        test_job = create(:ci_build, pipeline: pipeline, name: 'rspec 2 2', scheduling_type: :dag, ci_stage: test_stage, stage_idx: test_stage.position)

        create(:ci_build_need, build: test_job, name: 'my test job')
      end

      it 'reports the build needs and execution requirements', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/347290' do
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
            'previousStageJobsOrNeeds' => { 'nodes' => [
              a_hash_including('name' => 'my test job')
            ] }
          ),
          a_hash_including(
            'name' => 'docker 2 2',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => [] }
          ),
          a_hash_including(
            'name' => 'rspec 1 2',
            'needs' => { 'nodes' => [] },
            'previousStageJobsOrNeeds' => { 'nodes' => [
              a_hash_including('name' => 'docker 1 2'),
              a_hash_including('name' => 'docker 2 2')
            ] }
          ),
          a_hash_including(
            'name' => 'rspec 2 2',
            'needs' => { 'nodes' => [a_hash_including('name' => 'my test job')] },
            'previousStageJobsOrNeeds' => { 'nodes' => [
              a_hash_including('name' => 'my test job')
            ] }
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
