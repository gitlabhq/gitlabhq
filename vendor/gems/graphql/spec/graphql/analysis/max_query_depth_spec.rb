# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::MaxQueryDepth do
  let(:schema) {
    schema = Class.new(Dummy::Schema)
    schema.analysis_engine = GraphQL::Analysis::AST
    schema
  }
  let(:query_string) { "
    {
      cheese(id: 1) {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              similarCheese(source: SHEEP) {
                similarCheese(source: SHEEP) {
                  id
                }
              }
            }
          }
        }
      }
    }
  "}
  let(:max_depth) { nil }
  let(:query) {
    # Don't override `schema.max_depth` with `nil`
    options = max_depth ? { max_depth: max_depth } : {}
    GraphQL::Query.new(
      schema,
      query_string,
      variables: {},
      **options
    )
  }
  let(:result) {
    GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::MaxQueryDepth]).first
  }
  let(:multiplex) {
    GraphQL::Execution::Multiplex.new(
      schema: schema,
      queries: [query.dup, query.dup],
      context: {},
      max_complexity: nil
    )
  }
  let(:multiplex_result) {
    GraphQL::Analysis.analyze_multiplex(multiplex, [GraphQL::Analysis::MaxQueryDepth]).first
  }

  describe "when the query is deeper than max depth" do
    let(:max_depth) { 5 }

    it "adds an error message for a too-deep query" do
      assert_equal "Query has depth of 7, which exceeds max depth of 5", result.message
    end
  end

  describe "when a multiplex queries is deeper than max depth" do
    before do
      schema.max_depth = 5
    end

    it "adds an error message for a too-deep query on from multiplex analyzer" do
      assert_equal "Query has depth of 7, which exceeds max depth of 5", multiplex_result.message
    end
  end

  describe "when the query specifies a different max_depth" do
    let(:max_depth) { 100 }

    it "obeys that max_depth" do
      assert_nil result
    end
  end

  describe "When the query is not deeper than max_depth" do
    before do
      schema.max_depth = 100
    end

    it "doesn't add an error" do
      assert_nil result
    end
  end

  describe "when the max depth isn't set" do
    before do
      schema.max_depth = nil
    end

    it "doesn't add an error message" do
      assert_nil result
    end
  end

  describe "when a fragment exceeds max depth" do
    before do
      schema.max_depth = 4
    end

    let(:query_string) { "
      {
        cheese(id: 1) {
          ...moreFields
        }
      }

      fragment moreFields on Cheese {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              ...evenMoreFields
            }
          }
        }
      }

      fragment evenMoreFields on Cheese {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            id
          }
        }
      }
    "}

    it "adds an error message for a too-deep query" do
      assert_equal "Query has depth of 7, which exceeds max depth of 4", result.message
    end
  end

  describe "when the query would cause a stack error" do
    let(:query_string) {
      str = "query { cheese(id: 1) { ".dup
      n = 10_000
      n.times { str << "similarCheese(source: SHEEP) { " }
      str << "id "
      n.times { str << "} " }
      str << "} }"
      str
    }

    it "returns an error" do
      assert_equal ["This query is too large to execute."], query.result["errors"].map { |err| err["message"] }

      # Make sure `Schema.execute` works too
      execute_result = schema.execute(query_string)
      assert_equal ["This query is too large to execute."], execute_result["errors"].map { |err| err["message"] }
    end
  end

  it "counts introspection fields by default, but can be set to skip" do
    schema.max_depth = 3
    query_str = <<-GRAPHQL
    {
      __type(name: \"Abc\") {
        fields {
          type {
            ofType {
              name
            }
          }
        }
      }
    }
    GRAPHQL

    result = schema.execute(query_str)
    assert_equal ["Query has depth of 5, which exceeds max depth of 3"], result["errors"].map { |e| e["message"] }

    schema.max_depth(3, count_introspection_fields: false)

    result = schema.execute(query_str)
    assert_equal({ "__type" => nil }, result["data"])
  end
end
