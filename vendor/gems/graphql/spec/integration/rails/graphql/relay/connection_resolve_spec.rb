# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Relay::ConnectionResolve" do
  let(:query_string) { <<-GRAPHQL
    query getShips($name: String!, $testParentName: Boolean = false){
      rebels {
        ships(nameIncludes: $name) {
          edges {
            node {
              name
            }
          }
          parentClassName @include(if: $testParentName)
        }
      }
    }
    GRAPHQL
  }

  describe "when an execution error is returned" do
    it "adds an error" do
      result = star_wars_query(query_string, { "name" => "error"})
      assert_equal 1, result["errors"].length
      assert_equal "error from within connection", result["errors"][0]["message"]
    end

    it "adds an error for a lazy error" do
      result = star_wars_query(query_string, { "name" => "lazyError"})
      assert_equal 1, result["errors"].length
      assert_equal "lazy error from within connection", result["errors"][0]["message"]
    end

    it "adds an error for a lazy raised error" do
      result = star_wars_query(query_string, { "name" => "lazyRaisedError"})
      assert_equal 1, result["errors"].length
      assert_equal "lazy raised error from within connection", result["errors"][0]["message"]
    end

    it "adds an error for a raised error" do
      result = star_wars_query(query_string, { "name" => "raisedError"})
      assert_equal 1, result["errors"].length
      assert_equal "error raised from within connection", result["errors"][0]["message"]
    end
  end

  describe "when nil is returned" do
    it "becomes null" do
      result = star_wars_query(query_string, { "name" => "null" })
      conn = result["data"]["rebels"]["ships"]
      assert_nil conn
    end
  end
end
