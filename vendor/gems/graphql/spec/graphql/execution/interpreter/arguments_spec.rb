# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Execution::Interpreter::Arguments" do
  class InterpreterArgsTestSchema < GraphQL::Schema
    class SearchParams < GraphQL::Schema::InputObject
      argument :query, String, required: false
    end

    class Query < GraphQL::Schema::Object
      field :search, [String], null: false do
        argument :params, SearchParams, required: false
        argument :limit, Int
      end
    end

    query(Query)
  end

  def arguments(query_str)
    query = GraphQL::Query.new(InterpreterArgsTestSchema, query_str)
    ast_node = query.document.definitions.first.selections.first
    query_type = query.get_type("Query")
    field = query.get_field(query_type, "search")
    query.arguments_for(ast_node, field)
  end

  it "provides .dig" do
    query_str = <<-GRAPHQL
    {
      search(limit: 10, params: { query: "abcde" } )
    }
    GRAPHQL
    args = arguments(query_str)
    assert_equal 10, args.dig(:limit)
    assert_equal "abcde", args.dig(:params, :query)
    assert_nil args.dig(:nothing)
    assert_nil args.dig(:params, :nothing)
    assert_nil args.dig(:nothing, :nothing, :nothing)
  end

  it "is frozen, and so are its constituent hashes" do
    query_str = <<-GRAPHQL
    {
      search(limit: 10, params: { query: "abcde" } )
    }
    GRAPHQL
    args = arguments(query_str)

    assert args.frozen?
    assert args.argument_values.frozen?
    assert args.keyword_arguments.frozen?
  end
end
