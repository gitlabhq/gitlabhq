# frozen_string_literal: true
require "spec_helper"

describe "Query level Directive" do
  class QueryDirectiveSchema < GraphQL::Schema
    class DirectiveInput < GraphQL::Schema::InputObject
      argument :val, Integer
    end

    class InitInt < GraphQL::Schema::Directive
      locations(GraphQL::Schema::Directive::QUERY)
      argument(:val, Integer, "Initial integer value.", required: false)
      argument(:input, DirectiveInput, required: false)

      def self.resolve(obj, args, ctx)
        ctx[:int] = args[:val] || args[:input][:val] || 0
        yield
      end
    end

    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        context[:int] ||= 0
        context[:int] += 1
      end
    end

    directive(InitInt)
    query(Query)
  end

  it "returns an error if directive is not on the query level" do
    str = 'query TestDirective {
      int1: int @initInt(val: 10)
      int2: int
    }
    '

    res = QueryDirectiveSchema.execute(str)

    expected_errors = [
      {
        "message" => "'@initInt' can't be applied to fields (allowed: queries)",
        "locations" => [{ "line" => 2, "column" => 17 }],
        "path" => ["query TestDirective", "int1"],
        "extensions" => { "code" => "directiveCannotBeApplied", "targetName" => "fields", "name" => "initInt" }
      }
    ]
    assert_equal(expected_errors, res["errors"])
  end

  it "runs on the query level" do
    str = 'query TestDirective @initInt(val: 10) {
      int1: int
      int2: int
    }
    '

    res = QueryDirectiveSchema.execute(str)
    assert_equal({ "int1" => 11, "int2" => 12 }, res["data"])
  end

  it "works with input object arguments" do
    str = 'query TestDirective @initInt(input: { val: 12 }) {
      int1: int
      int2: int
    }
    '

    res = QueryDirectiveSchema.execute(str)
    assert_equal({ "int1" => 13, "int2" => 14 }, res["data"])

    error_str = 'query TestDirective @initInt(input: {val: "abc"}) {
      int1: int
      int2: int
    }
    '
    error_res = QueryDirectiveSchema.execute(error_str)
    assert_equal(["Argument 'val' on InputObject 'DirectiveInput' has an invalid value (\"abc\"). Expected type 'Int!'."], error_res["errors"].map { |e| e["message"] })
  end
end
