# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.jobs', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    create(:ci_pipeline, project: project, user: user)
  end

  let!(:job1) { create(:ci_build, pipeline: pipeline, name: 'job 1', user: user) }
  let!(:job2) { create(:ci_build, pipeline: pipeline, name: 'job 2', user: user) }

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

  describe '.userId' do
    let_it_be(:other_user) { create(:user) }

    let!(:other_user_job) { create(:ci_build, pipeline: pipeline, name: 'other user job', user: other_user) }
    let!(:job_without_user) { create(:ci_build, pipeline: pipeline, name: 'job without user', user: nil) }

    let(:query) { user_id_query('name userId') }

    def user_id_query(fields)
      <<~QUERY
      {
        project(fullPath: "#{project.full_path}") {
          jobs {
            nodes {
              #{fields}
            }
          }
        }
      }
      QUERY
    end

    it 'returns the Global ID of the user of each job' do
      post_graphql(query, current_user: user)

      expect_graphql_errors_to_be_empty
      expect(graphql_data_at(:project, :jobs, :nodes)).to contain_exactly(
        { 'name' => 'job 1', 'userId' => user.to_global_id.to_s },
        { 'name' => 'job 2', 'userId' => user.to_global_id.to_s },
        { 'name' => 'other user job', 'userId' => other_user.to_global_id.to_s },
        { 'name' => 'job without user', 'userId' => nil }
      )
    end

    context 'when a manual job is played by another user' do
      let_it_be(:player) { create(:user, maintainer_of: project) }

      let!(:manual_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'manual job', user: user) }

      before do
        manual_job.play(player)
      end

      it 'returns the Global ID of the user who played the job' do
        post_graphql(query, current_user: user)

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :jobs, :nodes)).to include(
          { 'name' => 'manual job', 'userId' => player.to_global_id.to_s }
        )
      end
    end

    it 'does not add queries', :request_store, :use_sql_query_cache do
      post_graphql(query, current_user: user)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(user_id_query('name'), current_user: user)
      end

      expect { post_graphql(query, current_user: user) }.not_to exceed_all_query_limit(control)
    end
  end
end
