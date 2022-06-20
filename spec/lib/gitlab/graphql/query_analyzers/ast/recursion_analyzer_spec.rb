# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::QueryAnalyzers::AST::RecursionAnalyzer do
  let(:query) { GraphQL::Query.new(GitlabSchema, document: document, context: {}, variables: { body: 'some note' }) }

  context 'when recursion threshold not exceeded' do
    let(:document) do
      GraphQL.parse <<-GRAPHQL
          query recurse {
            group(fullPath: "h5bp") {
              projects {
                nodes {
                  name
                  group {
                    projects {
                      nodes {
                        name
                      }
                    }
                  }
                }
              }
            }
          }
      GRAPHQL
    end

    it 'returns the complexity, depth, duration, etc' do
      result = GraphQL::Analysis::AST.analyze_query(query, [described_class], multiplex_analyzers: [])

      expect(result.first).to be_nil
    end
  end

  context 'when recursion threshold exceeded' do
    let(:document) do
      GraphQL.parse <<-GRAPHQL
          query recurse {
            group(fullPath: "h5bp") {
              projects {
                nodes {
                  name
                  group {
                    projects {
                      nodes {
                        name
                        group {
                          projects {
                            nodes {
                              name
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
      GRAPHQL
    end

    it 'returns error' do
      result = GraphQL::Analysis::AST.analyze_query(query, [described_class], multiplex_analyzers: [])

      expect(result.first.is_a?(GraphQL::AnalysisError)).to be_truthy
    end
  end
end
