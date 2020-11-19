# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.pipeline.stages.groups.jobs' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:user) { create(:user) }
  let(:pipeline) do
    pipeline = create(:ci_pipeline, project: project, user: user)
    stage = create(:ci_stage_entity, pipeline: pipeline, name: 'first')
    create(:commit_status, stage_id: stage.id, pipeline: pipeline, name: 'my test job')

    pipeline
  end

  def first(field)
    [field.pluralize, 'nodes', 0]
  end

  let(:jobs_graphql_data) { graphql_data.dig(*%w[project pipeline], *first('stage'), *first('group'), 'jobs', 'nodes') }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            stages {
              nodes {
                name
                groups {
                  nodes {
                    name
                    jobs {
                      nodes {
                        name
                        pipeline {
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
    )
  end

  it 'returns the jobs of a pipeline stage' do
    post_graphql(query, current_user: user)

    expect(jobs_graphql_data).to contain_exactly(a_hash_including('name' => 'my test job'))
  end

  context 'when fetching jobs from the pipeline' do
    it 'avoids N+1 queries', :aggregate_failures do
      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: user)
      end

      build_stage = create(:ci_stage_entity, name: 'build', pipeline: pipeline)
      test_stage = create(:ci_stage_entity, name: 'test', pipeline: pipeline)
      create(:commit_status, pipeline: pipeline, stage_id: build_stage.id, name: 'docker 1 2')
      create(:commit_status, pipeline: pipeline, stage_id: build_stage.id, name: 'docker 2 2')
      create(:commit_status, pipeline: pipeline, stage_id: test_stage.id, name: 'rspec 1 2')
      create(:commit_status, pipeline: pipeline, stage_id: test_stage.id, name: 'rspec 2 2')

      expect do
        post_graphql(query, current_user: user)
      end.not_to exceed_query_limit(control_count)

      expect(response).to have_gitlab_http_status(:ok)

      build_stage = graphql_data.dig('project', 'pipeline', 'stages', 'nodes').find do |stage|
        stage['name'] == 'build'
      end
      test_stage = graphql_data.dig('project', 'pipeline', 'stages', 'nodes').find do |stage|
        stage['name'] == 'test'
      end
      docker_group = build_stage.dig('groups', 'nodes').first
      rspec_group = test_stage.dig('groups', 'nodes').first

      expect(docker_group['name']).to eq('docker')
      expect(rspec_group['name']).to eq('rspec')

      docker_jobs = docker_group.dig('jobs', 'nodes')
      rspec_jobs = rspec_group.dig('jobs', 'nodes')

      expect(docker_jobs).to eq([
        {
          'name' => 'docker 1 2',
          'pipeline' => { 'id' => pipeline.to_global_id.to_s }
        },
        {
          'name' => 'docker 2 2',
          'pipeline' => { 'id' => pipeline.to_global_id.to_s }
        }
      ])

      expect(rspec_jobs).to eq([
        {
          'name' => 'rspec 1 2',
          'pipeline' => { 'id' => pipeline.to_global_id.to_s }
        },
        {
          'name' => 'rspec 2 2',
          'pipeline' => { 'id' => pipeline.to_global_id.to_s }
        }
      ])
    end
  end
end
