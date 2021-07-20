# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.pipeline' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  def all(*fields)
    fields.flat_map { |f| [f, :nodes] }
  end

  describe '.stages.groups.jobs' do
    let(:pipeline) do
      pipeline = create(:ci_pipeline, project: project, user: user)
      stage = create(:ci_stage_entity, project: project, pipeline: pipeline, name: 'first')
      create(:ci_build, stage_id: stage.id, pipeline: pipeline, name: 'my test job')

      pipeline
    end

    let(:jobs_graphql_data) { graphql_data_at(:project, :pipeline, *all(:stages, :groups, :jobs)) }

    let(:first_n) { var('Int') }

    let(:query) do
      with_signature([first_n], wrap_fields(query_graphql_path([
        [:project,  { full_path: project.full_path }],
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
                detailedStatus {
                  id
                }
                name
                needs {
                  nodes { #{all_graphql_fields_for('CiBuildNeed')} }
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

    context 'when there are build needs' do
      before do
        pipeline.statuses.each do |build|
          create_list(:ci_build_need, 2, build: build)
        end
      end

      it 'reports the build needs' do
        post_graphql(query, current_user: user)

        expect(jobs_graphql_data).to contain_exactly a_hash_including(
          'needs' => a_hash_including(
            'nodes' => contain_exactly(
              a_hash_including('name' => String),
              a_hash_including('name' => String)
            )
          )
        )
      end
    end

    it 'returns the jobs of a pipeline stage' do
      post_graphql(query, current_user: user)

      expect(jobs_graphql_data).to contain_exactly(a_hash_including('name' => 'my test job'))
    end

    describe 'performance' do
      before do
        build_stage = create(:ci_stage_entity, position: 2, name: 'build', project: project, pipeline: pipeline)
        test_stage = create(:ci_stage_entity, position: 3, name: 'test', project: project, pipeline: pipeline)
        create(:commit_status, pipeline: pipeline, stage_id: build_stage.id, name: 'docker 1 2')
        create(:commit_status, pipeline: pipeline, stage_id: build_stage.id, name: 'docker 2 2')
        create(:commit_status, pipeline: pipeline, stage_id: test_stage.id, name: 'rspec 1 2')
        create(:commit_status, pipeline: pipeline, stage_id: test_stage.id, name: 'rspec 2 2')
      end

      it 'can find the first stage' do
        post_graphql(query, current_user: user, variables: first_n.with(1))

        expect(jobs_graphql_data).to contain_exactly(a_hash_including('name' => 'my test job'))
      end

      it 'can find all stages' do
        post_graphql(query, current_user: user, variables: first_n.with(3))

        expect(jobs_graphql_data).to contain_exactly(
          a_hash_including('name' => 'my test job'),
          a_hash_including('name' => 'docker 1 2'),
          a_hash_including('name' => 'docker 2 2'),
          a_hash_including('name' => 'rspec 1 2'),
          a_hash_including('name' => 'rspec 2 2')
        )
      end

      it 'avoids N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: user, variables: first_n.with(1))
        end

        expect do
          post_graphql(query, current_user: user, variables: first_n.with(3))
        end.not_to exceed_query_limit(control_count)
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
      )
    end

    context 'when the job is a build' do
      it "returns the build's artifacts" do
        create(:ci_build, :artifacts, pipeline: pipeline)

        post_graphql(query, current_user: user)

        job_data = graphql_data.dig('project', 'pipeline', 'jobs', 'nodes').first
        expect(job_data.dig('artifacts', 'nodes').count).to be(2)
      end
    end

    context 'when the job is not a build' do
      it 'returns nil' do
        create(:ci_bridge, pipeline: pipeline)

        post_graphql(query, current_user: user)

        job_data = graphql_data.dig('project', 'pipeline', 'jobs', 'nodes').first
        expect(job_data['artifacts']).to be_nil
      end
    end
  end
end
