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

  %w[rawTextBlob rawBlob base64EncodedBlob plainData].each do |field_name|
    context "for multiple paths with #{field_name}" do
      it 'blocks the query because of high complexity' do
        query_string = <<~GRAPHQL
        {
          project(fullPath: "#{project.full_path}") {
            repository {
              blobs(paths: ["a", "b"]) {
                nodes {
                  #{field_name}
                }
              }
            }
          }
        }
        GRAPHQL

        expect(calculate_query_complexity(query_string)).to be > GitlabSchema::DEFAULT_MAX_COMPLEXITY
      end
    end
  end
end
