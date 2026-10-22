# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting blame for a blob in a project repository', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: current_user) }
  let_it_be(:other_project) { create(:project, :repository, developers: current_user) }
  let_it_be(:public_project) { create(:project, :public, :repository) }

  let(:path) { 'files/ruby/popen.rb' }

  def blame_query(target_project, paths = [path])
    graphql_query_for(
      'project',
      { 'fullPath' => target_project.full_path },
      query_graphql_field('repository', {}, <<~GQL)
        blobs(paths: #{paths.inspect}, ref: "master") {
          nodes {
            blame(fromLine: 1, toLine: 2) {
              firstLine
            }
          }
        }
      GQL
    )
  end

  it 'returns the blame' do
    post_graphql(blame_query(project), current_user: current_user)

    expect(graphql_data_at(:project, :repository, :blobs, :nodes, 0, :blame)).to be_present
  end

  context 'when one query asks for blame on several blobs', :clean_gitlab_redis_rate_limiting do
    let(:paths) { [path, 'files/ruby/regex.rb'] }

    before do
      stub_application_setting(project_repositories_blame_limit: 1)
    end

    it 'charges the limit once per blob', :aggregate_failures do
      post_graphql(blame_query(project, paths), current_user: current_user)

      blames = graphql_data_at(:project, :repository, :blobs, :nodes).pluck('blame')

      expect(blames.compact.size).to eq(1)
      expect_graphql_errors_to_include('This endpoint has been requested too many times. Try again later.')
    end
  end

  context 'when unauthenticated', :clean_gitlab_redis_rate_limiting do
    before do
      stub_application_setting(
        project_repositories_blame_limit: 1,
        project_repositories_blame_unauthenticated_limit: 1
      )
    end

    it 'resolves blame and counts it against the per-IP limit' do
      post_graphql(blame_query(public_project), current_user: nil)

      expect(graphql_data_at(:project, :repository, :blobs, :nodes, 0, :blame)).to be_present

      post_graphql(blame_query(public_project), current_user: nil)

      expect_graphql_errors_to_include('This endpoint has been requested too many times. Try again later.')
    end

    it 'does not draw on the authenticated budget' do
      post_graphql(blame_query(public_project), current_user: nil)
      post_graphql(blame_query(public_project), current_user: nil)
      expect_graphql_errors_to_include('This endpoint has been requested too many times. Try again later.')

      post_graphql(blame_query(public_project), current_user: current_user)

      expect(graphql_data_at(:project, :repository, :blobs, :nodes, 0, :blame)).to be_present
    end
  end

  it_behaves_like 'rate limited endpoint', rate_limit_key: :project_repositories_blame, graphql: true do
    def request
      post_graphql(blame_query(project), current_user: current_user)
    end

    def request_with_second_scope
      post_graphql(blame_query(other_project), current_user: current_user)
    end
  end
end
