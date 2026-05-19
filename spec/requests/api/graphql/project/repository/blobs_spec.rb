# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting blobs in a project repository', feature_category: :source_code_management do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let(:current_user) { project.first_owner }
  let(:paths) { ["CONTRIBUTING.md", "README.md"] }
  let(:ref) { project.default_branch }
  let(:fields) do
    <<~QUERY
      blobs(paths:#{paths.inspect}, ref:#{ref.inspect}) {
        nodes {
          #{all_graphql_fields_for('repository_blob'.classify)}
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('repository', {}, fields)
    )
  end

  subject(:blobs) { graphql_data_at(:project, :repository, :blobs, :nodes) }

  it 'returns the blob' do
    post_graphql(query, current_user: current_user)

    expect(blobs).to match_array(paths.map { |path| a_hash_including('path' => path) })
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL',
    [:read_project, :read_code, :read_repository_blob] do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field('repository', {}, <<~GQL)
          blobs(paths:#{paths.inspect}, ref:#{ref.inspect}) {
            nodes {
              path
              name
            }
          }
        GQL
      )
    end

    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end
end
