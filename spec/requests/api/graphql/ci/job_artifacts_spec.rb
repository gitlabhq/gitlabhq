# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines.jobs.artifacts', feature_category: :build do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipelines {
            nodes {
              jobs {
                nodes {
                  artifacts {
                    nodes {
                      downloadPath
                      fileType
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

  it 'returns the fields for the artifacts' do
    job = create(:ci_build, pipeline: pipeline)
    create(:ci_job_artifact, :junit, job: job)

    post_graphql(query, current_user: user)

    expect(response).to have_gitlab_http_status(:ok)

    pipelines_data = graphql_data.dig('project', 'pipelines', 'nodes')
    jobs_data = pipelines_data.first.dig('jobs', 'nodes')
    artifact_data = jobs_data.first.dig('artifacts', 'nodes').first

    expect(artifact_data['downloadPath']).to eq(
      "/#{project.full_path}/-/jobs/#{job.id}/artifacts/download?file_type=junit"
    )
    expect(artifact_data['fileType']).to eq('JUNIT')
  end
end
