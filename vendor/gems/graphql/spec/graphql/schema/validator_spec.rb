# frozen_string_literal: true
require "spec_helper"
require_relative "./validator/validator_helpers"

describe GraphQL::Schema::Validator do
  include ValidatorHelpers

  class CustomValidator < GraphQL::Schema::Validator
    def initialize(equal_to:, **rest)
      @equal_to = equal_to
      super(**rest)
    end

    def validate(object, context, value)
      if value == @equal_to
        nil
      else
        "%{validated} doesn't have the right the right value"
      end
    end
  end

  class CustomErrorValidator < GraphQL::Schema::Validator
    def validate(obj, ctx, value)
      if value != 7
        raise GraphQL::ExecutionError.new("#{@validated.path} must be `7`, not `#{value}`", extensions: { requiredValue: 7, actualValue: value })
      end
    end
  end

  before do
    GraphQL::Schema::Validator.install(:custom, CustomValidator)
    GraphQL::Schema::Validator.install(:custom_error, CustomErrorValidator)
  end

  after do
    GraphQL::Schema::Validator.uninstall(:custom)
    GraphQL::Schema::Validator.uninstall(:custom_error)
  end

  build_tests(CustomValidator, Integer, [
    {
      name: "with a validator class as name",
      config: { equal_to: 2 },
      cases: [
        { query: "{ validated(value: 2) }", error_messages: [], result: 2 },
        { query: "{ validated(value: 3) }", error_messages: ["value doesn't have the right the right value"], result: nil },
      ]
    }
  ])

  build_tests(:custom, Integer, [
    {
      name: "with an installed symbol name",
      config: { equal_to: 4 },
      cases: [
        { query: "{ validated(value: 4) }", error_messages: [], result: 4 },
        { query: "{ validated(value: 3) }", error_messages: ["value doesn't have the right the right value"], result: nil },
      ]
    }
  ])

  it "works with custom raised errors" do
    schema = build_schema(Integer, { custom_error: {} })
    res = schema.execute("{ validated(value: 7) }")
    assert_equal 7, res["data"]["validated"]

    res = schema.execute("{ validated(value: 77) }")
    expected_error = {
      "message"=>"Query.validated.value must be `7`, not `77`",
      "locations"=>[{"line"=>1, "column"=>3}],
      "path"=>["validated"],
      "extensions"=>{"requiredValue"=>7, "actualValue"=>77}
    }
    assert_equal [expected_error], res["errors"]
  end

  it "does something with multiple validators" do
    schema = build_schema(String, { length: { minimum: 5 }, inclusion: { in: ["0", "123456", "678910"] }})
    # Both validators pass:
    res = schema.execute("{ validated(value: \"123456\") }")
    assert_nil res["errors"]
    assert_equal "123456", res["data"]["validated"]

    # The length validator fails:
    res2 = schema.execute("{ validated(value: \"0\") }")
    assert_nil res2["data"]["validated"]
    assert_equal ["value is too short (minimum is 5)"], res2["errors"].map { |e| e["message"] }

    # The inclusion validator fails:
    res3 = schema.execute("{ validated(value: \"00000000\") }")
    assert_nil res3["data"]["validated"]
    assert_equal ["value is not included in the list"], res3["errors"].map { |e| e["message"] }

    # Both validators fail:
    res4 = schema.execute("{ validated(value: \"1\") }")
    assert_nil res4["data"]["validated"]
    errs = [
      "value is too short (minimum is 5), value is not included in the list",
    ]
    assert_equal errs, res4["errors"].map { |e| e["message"] }

    # Two fields with different errors
    res5 = schema.execute("{ v1: validated(value: \"0\") v2: validated(value: \"123456\") v3: validated(value: \"abcdefg\") }")
    expected_data = {"v1"=>nil, "v2"=>"123456", "v3"=>nil}
    assert_equal expected_data, res5["data"]
    errs = [
      {
        "message" => "value is too short (minimum is 5)",
        "locations" => [{"line"=>1, "column"=>3}],
        "path" => ["v1"]
      }, {
        "message" => "value is not included in the list",
        "locations" => [{"line"=>1, "column"=>60}],
        "path" => ["v3"]
      }
    ]
    assert_equal errs, res5["errors"]
  end

  it "validates each item in the list" do
    schema = build_schema(Integer, { numericality: { greater_than: 5 } })
    res = schema.execute("{ list { validated(value: 6) } }")
    expected_data = {
      "list" => [
        { "validated" => 6 },
        { "validated" => 6 },
        { "validated" => 6 },
      ]
    }
    assert_equal expected_data, res["data"]

    res = schema.execute("{ list { validated(value: 3) } }")
    expected_response = {
      "data" => {
        "list" => [
          { "validated" => nil },
          { "validated" => nil },
          { "validated" => nil },
        ]
      },
      "errors" => [
        {"message"=>"value must be greater than 5", "locations"=>[{"line"=>1, "column"=>10}], "path"=>["list", 0, "validated"]},
        {"message"=>"value must be greater than 5", "locations"=>[{"line"=>1, "column"=>10}], "path"=>["list", 1, "validated"]},
        {"message"=>"value must be greater than 5", "locations"=>[{"line"=>1, "column"=>10}], "path"=>["list", 2, "validated"]},
      ]
    }
    assert_equal expected_response, res
  end

  describe "Validator inheritance" do
    class ValidationInheritanceSchema < GraphQL::Schema
      class BaseValidatedInput < GraphQL::Schema::InputObject
        argument :int, Integer, required: false
        argument :other_int, Integer, required: false
        validates required: { one_of: [:int, :other_int] }
      end

      class IntInput < BaseValidatedInput
        graphql_name "IntInput"
      end

      class BaseValidatedResolver < GraphQL::Schema::Resolver
        argument :int, Integer, required: false
        argument :other_int, Integer, required: false
        validates required: { one_of: [:int, :other_int] }
        type Integer, null: true

        def resolve(int: nil, other_int: nil)
          int || other_int
        end
      end

      class IntResolver < BaseValidatedResolver
      end

      class Query < GraphQL::Schema::Object
        field :int_input, Int do
          argument :input, IntInput
        end

        def int_input(input:)
          input[:int] || input[:other_int]
        end

        field :int, resolver: IntResolver
      end

      query(Query)
    end

    it "works with input objects" do
      res = ValidationInheritanceSchema.execute("{ intInput(input: { int: 1 }) }")
      assert_equal 1, res["data"]["intInput"]

      res = ValidationInheritanceSchema.execute("{ intInput(input: { int: 1, otherInt: 2 }) }")
      assert_nil res["data"]["intInput"]
      assert_equal ["IntInput must include exactly one of the following arguments: int, otherInt."], res["errors"].map { |e| e["message"] }
    end

    it "works with resolvers" do
      res = ValidationInheritanceSchema.execute("{ int(int: 1) }")
      assert_equal 1, res["data"]["int"]

      res = ValidationInheritanceSchema.execute("{ int(int: 1, otherInt: 2) }")
      assert_nil res["data"]["int"]
      assert_equal ["int must include exactly one of the following arguments: int, otherInt."], res["errors"].map { |e| e["message"] }
    end
  end
end
