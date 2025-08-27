# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'snippets', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:snippets) { create_list(:personal_snippet, 3, :repository, author: current_user) }

  describe 'querying for all fields' do
    let(:query) do
      graphql_query_for(:snippets, { ids: [global_id_of(snippets.first)] }, <<~SELECT)
        nodes { #{all_graphql_fields_for('Snippet')} }
      SELECT
    end

    it 'can successfully query for snippets and their blobs' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:snippets, :nodes)).to be_one
      expect(graphql_data_at(:snippets, :nodes, :blobs, :nodes)).to be_present
    end
  end

  describe 'snippet blob complexity' do
    it 'applies higher complexity to blob content fields' do
      blob_type = Types::Snippets::BlobType

      expect(blob_type.fields['rawPlainData'].complexity).to eq(10)
      expect(blob_type.fields['richData'].complexity).to eq(10)
      expect(blob_type.fields['plainData'].complexity).to eq(10)
    end

    it 'limits more than 8 aliased blob data requests' do
      # create query with 9 aliased rawPlainData fields
      query_string = build_blob_query(%w[a b c d e f g h i].to_h { |key| [key.to_sym, 'rawPlainData'] })
      complexity_score = calculate_query_complexity(query_string)

      expect(complexity_score).to be > GitlabSchema::DEFAULT_MAX_COMPLEXITY
    end

    it 'allows queries within complexity limits' do
      query_string = build_blob_query({ field1: 'rawPlainData', field2: 'name' })
      complexity_score = calculate_query_complexity(query_string)

      expect(complexity_score).to be < GitlabSchema::DEFAULT_MAX_COMPLEXITY
    end
  end

  describe 'project snippets complexity' do
    let_it_be(:project) { create(:project, :public) }

    it 'blocks high complexity queries with multiple project aliases' do
      # Build query with multiple project aliases requesting blob data
      query_string = <<~GRAPHQL
        query {
          p1: project(fullPath: "#{project.full_path}") {
            snippets(first: 100) {
              nodes {
                blobs {
                  nodes {
                    rawPlainData
                  }
                }
              }
            }
          }
          p2: project(fullPath: "#{project.full_path}") {
            snippets(first: 100) {
              nodes {
                blobs {
                  nodes {
                    rawPlainData
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      complexity_score = calculate_query_complexity(query_string)
      expect(complexity_score).to be > GitlabSchema::DEFAULT_MAX_COMPLEXITY
    end

    it 'allows single-project snippet queries' do
      query_string = <<~GRAPHQL
        query {
          project(fullPath: "#{project.full_path}") {
            snippets(first: 100) {
              nodes {
                title
                blobs {
                  nodes {
                    rawPlainData
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      complexity_score = calculate_query_complexity(query_string)
      expect(complexity_score).to be < GitlabSchema::DEFAULT_MAX_COMPLEXITY
    end
  end

  private

  def build_blob_query(field_map)
    field_requests = field_map.map { |alias_name, field| "#{alias_name}: #{field}" }

    <<~GRAPHQL
    query {
      project(fullPath: "test") {
        snippets {
          nodes {
            blobs {
              nodes {
                #{field_requests.join("\n")}
              }
            }
          }
        }
      }
    }
    GRAPHQL
  end

  def calculate_query_complexity(query_string)
    query = GraphQL::Query.new(GitlabSchema, query_string)
    analyzer = GraphQL::Analysis::AST::QueryComplexity
    GraphQL::Analysis::AST.analyze_query(query, [analyzer]).first
  end
end
