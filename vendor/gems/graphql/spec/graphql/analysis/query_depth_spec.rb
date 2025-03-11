# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::QueryDepth do
  let(:result) { GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::QueryDepth]) }
  let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables) }
  let(:variables) { {} }

  describe "multiple operations" do
    let(:query_string) {%|
      query Cheese1 {
        cheese1: cheese(id: 1) {
          id
          flavor
        }
      }

      query Cheese2 {
        cheese(id: 2) {
          similarCheese(source: SHEEP) {
            ... on Cheese {
              similarCheese(source: SHEEP) {
                id
              }
            }
          }
        }
      }
    |}

    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables, operation_name: "Cheese1") }

    it "analyzes the selected operation only" do
      depth = result.first
      assert_equal 2, depth
    end
  end

  describe "simple queries" do
    let(:query_string) {%|
      query cheeses($isIncluded: Boolean = true){
        # depth of 2
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # depth of 4
        cheese2: cheese(id: 2) @include(if: $isIncluded) {
          similarCheese(source: SHEEP) {
            ... on Cheese {
              similarCheese(source: SHEEP) {
                id
              }
            }
          }
        }
      }
    |}

    it "finds the max depth" do
      depth = result.first
      assert_equal 4, depth
    end

    describe "with directives" do
      let(:variables) { { "isIncluded" => false } }

      it "doesn't count skipped fields" do
        assert_equal 2, result.first
      end
    end
  end

  describe "query with fragments" do
    let(:query_string) {%|
      {
        # depth of 2
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # depth of 4
        cheese2: cheese(id: 2) {
          ... cheeseFields1
        }
      }

      fragment cheeseFields1 on Cheese {
        similarCheese(source: COW) {
          id
          ... cheeseFields2
        }
      }

      fragment cheeseFields2 on Cheese {
        similarCheese(source: SHEEP) {
          id
        }
      }
    |}

    it "finds the max depth" do
      assert_equal 4, result.first
    end
  end
end
