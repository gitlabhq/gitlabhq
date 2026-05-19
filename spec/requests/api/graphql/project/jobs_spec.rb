# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.jobs', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    create(:ci_pipeline, project: project, user: user)
  end

  let!(:job1) { create(:ci_build, pipeline: pipeline, name: 'job 1') }
  let!(:job2) { create(:ci_build, pipeline: pipeline, name: 'job 2') }

  let(:query) do
    <<~QUERY
    {
      project(fullPath: "#{project.full_path}") {
        jobs {
          nodes {
            name
          }
        }
      }
    }
    QUERY
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_job] do
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }

    before_all do
      project.add_developer(user)
    end
  end

  it 'fetches jobs' do
    post_graphql(query, current_user: user)
    expect_graphql_errors_to_be_empty

    expect(graphql_data['project']['jobs']['nodes'].pluck('name')).to contain_exactly('job 1', 'job 2')
  end
end
