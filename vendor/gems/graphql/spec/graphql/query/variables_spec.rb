# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Query::Variables" do
  module VariablesTest
    class MaxValidationSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :items, [String], null: false do
          argument :a, Int
          argument :b, Int
          argument :c, Int
        end

        def items(a:, b:, c:)
          [a, b, c].map(&:to_s)
        end
      end

      query(Query)
    end
  end

  let(:variables) { {a: "1", b: "1", c: "1"} }
  let(:query_string) { "query($a: Int!, $b: Int!, $c: Int!) { items(a: $a, b: $b, c: $c)}" }

  describe "when there are no variable errors" do
    let(:schema) { VariablesTest::MaxValidationSchema }
    let(:variables) { {a: 1, b: 1, c: 1} }

    it "does not return any error" do
      res = schema.execute(query_string, variables: variables)
      assert_nil res["errors"]
    end
  end

  describe "when validate_max_errors is nil" do
    let(:schema) { VariablesTest::MaxValidationSchema }

    it "returns all errors" do
      res = schema.execute(query_string, variables: variables)
      assert_equal 3, res["errors"].count
    end
  end

  describe "when max validation error is set" do
    class TestSchema < VariablesTest::MaxValidationSchema
      validate_max_errors(2)
    end
    let(:schema) { TestSchema }

    describe "when errors are more than validate_max_value value" do
      it "raises only as many errors as the validate_max_errors value and appends the too many errors message" do
        res = schema.execute(query_string, variables: variables)
        assert_equal 3, res["errors"].count
        assert_match(/Too many errors processing variables/, res["errors"].last["message"])
      end
    end

    describe "when errors are equal with validate_max_value" do
      let(:variables) { {a: 1, b: "1", c: "1"} }

      it "raises all errors" do
        res = schema.execute(query_string, variables: variables)
        assert_equal 2, res["errors"].count
      end
    end

    describe "when variables are empty" do
      let(:variables) { {} }

      it "raises all errors" do
        res = schema.execute(query_string, variables: variables)
        assert_equal 3, res["errors"].count
        assert_match(/Too many errors processing variables/, res["errors"].last["message"])
      end
    end
  end

  describe "when an invalid enum value is given" do
    class EnumVariableSchema < GraphQL::Schema
      class Filter < GraphQL::Schema::Enum
        value(:contains) { def visible?(ctx); !ctx[:hide_enum_value]; end }
        value(:equals) { def visible?(ctx); !ctx[:hide_enum_value]; end }

        def self.visible?(ctx)
          !ctx[:hide_enum]
        end
      end

      class FilterInput < GraphQL::Schema::InputObject
        argument :filter, Filter, default_value: "contains" do
          def visible?(_ctx); true; end
        end
      end

      class Query < GraphQL::Schema::Object
        field :filter, String do
          argument :input, FilterInput
        end

        def filter(input:)
          input.filter.to_s
        end
      end

      query(Query)
    end

    it "handles the error nicely" do
      query_str = "query EchoFilter($input: FilterInput!) { filter(input: $input) }"
      variables = { "input"  => { "filter" => "contains" } }

      query = GraphQL::Query.new(
        EnumVariableSchema,
        query_str,
        variables: variables,
        context: { hide_enum_value: true }
      )

      assert_raises GraphQL::Schema::Enum::MissingValuesError do
        query.result
      end

      query2 = GraphQL::Query.new(
        EnumVariableSchema,
        query_str,
        variables: variables,
        context: { hide_enum_value: true, hide_enum: true }
      )

      expected_messages = [
        "Variable $input of type FilterInput! was provided invalid value for filter (Field is not defined on FilterInput)"
      ]

      assert query2.variables
      assert_equal expected_messages, query2.result["errors"].map { |err| err["message"] }
    end
  end
end
