# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:first_user) { create(:user) }
  let_it_be(:second_user) { create(:user) }

  describe '.jobs' do
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipelines {
              nodes {
                jobs {
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

    it 'fetches the jobs without an N+1' do
      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 1')

      control_count = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: first_user)
      end

      pipeline = create(:ci_pipeline, project: project)
      create(:ci_build, pipeline: pipeline, name: 'Job 2')

      expect do
        post_graphql(query, current_user: second_user)
      end.not_to exceed_query_limit(control_count)

      expect(response).to have_gitlab_http_status(:ok)

      pipelines_data = graphql_data.dig('project', 'pipelines', 'nodes')

      job_names = pipelines_data.map do |pipeline_data|
        jobs_data = pipeline_data.dig('jobs', 'nodes')
        jobs_data.map { |job_data| job_data['name'] }
      end.flatten

      expect(job_names).to contain_exactly('Job 1', 'Job 2')
    end
  end
end
