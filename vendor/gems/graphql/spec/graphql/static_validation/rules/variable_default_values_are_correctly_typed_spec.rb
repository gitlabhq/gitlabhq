# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese(
      $id:        Int = 1,
      $str:       String!,
      $badInt:    Int = "abc",
      $input:     DairyProductInput = {source: YAK, fatContent: 1},
      $badInput:  DairyProductInput = {source: YAK, fatContent: true},
      $nonNull:  Int! = 1,
    ) {
      cheese1: cheese(id: $id) { source }
      cheese2: cheese(id: $badInt) { source }
      cheese3: cheese(id: $nonNull) { source }
      search1: searchDairy(product: [$input]) { __typename }
      search2: searchDairy(product: [$badInput]) { __typename }
      __type(name: $str) { name }
    }
  |}

  it "finds default values that don't match their types" do
    expected = [
      {
        "message"=>"Could not coerce value \"abc\" to Int",
        "locations"=>[{"line"=>5, "column"=>7}],
        "path"=>["query getCheese"],
        "extensions"=>{"code"=>"defaultValueInvalidType", "variableName"=>"badInt", "typeName"=>"Int"}
      },
      {
        "message"=>"Could not coerce value true to Float",
        "locations"=>[{"line"=>7, "column"=>7}],
        "path"=>["query getCheese"],
        "extensions"=>{"code"=>"defaultValueInvalidType", "variableName"=>"badInput", "typeName"=>"DairyProductInput"}
      },
    ]
    assert_equal(expected, errors)
  end

  it "returns a client error when the type isn't found" do
    res = schema.execute <<-GRAPHQL
      query GetCheese($msg: IDX = 1) {
        cheese(id: $msg) @skip(if: true) { flavor }
      }
    GRAPHQL

    assert_equal false, res.key?("data")
    assert_equal 1, res["errors"].length
    assert_equal "IDX isn't a defined input type (on $msg) (Did you mean `ID`?)", res["errors"][0]["message"]
  end

  describe "null default values" do
    describe "variables with valid default null values" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(a: Int, b: String, c: ComplexInput): Int
          }

          input ComplexInput {
            requiredField: Boolean!
            intField: Int
          }
        |)
      }

      let(:query_string) {%|
        query getCheese(
          $a: Int = null,
          $b: String = null,
          $c: ComplexInput = { requiredField: true, intField: null }
        ) {
          field(a: $a, b: $b, c: $c)
        }
      |}

      it "finds no errors" do
        assert_equal [], errors
      end
    end

    describe "variables with invalid default null values" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(a: Int!, b: String!, c: ComplexInput): Int
          }

          input ComplexInput {
            requiredField: Boolean!
            intField: Int
          }
        |)
      }

      let(:query_string) {%|
        query getCheese(
          $a: Int! = null,
          $b: String! = null,
          $c: ComplexInput = { requiredField: null, intField: null }
        ) {
          field(a: $a, b: $b, c: $c)
        }
      |}

      it "finds errors" do
        expected = [
          {
            "message"=>"Default value for $a doesn't match type Int!",
            "locations"=>[{"line"=>3, "column"=>11}],
            "path"=>["query getCheese"],
            "extensions"=> {"code"=>"defaultValueInvalidType", "variableName"=>"a", "typeName"=>"Int!"}
          },
          {
            "message"=>"Default value for $b doesn't match type String!",
            "locations"=>[{"line"=>4, "column"=>11}],
            "path"=>["query getCheese"],
            "extensions"=>{"code"=>"defaultValueInvalidType", "variableName"=>"b", "typeName"=>"String!"}
          },
          {
            "message"=>"Default value for $c doesn't match type ComplexInput",
            "locations"=>[{"line"=>5, "column"=>11}],
            "path"=>["query getCheese"],
            "extensions"=>{"code"=>"defaultValueInvalidType", "variableName"=>"c", "typeName"=>"ComplexInput"}
          }
        ]
        assert_equal expected, errors
      end
    end
  end

  describe "custom error messages" do
    class CustomErrorMessagesSchema2 < GraphQL::Schema
      class TimeType < GraphQL::Schema::Scalar
        description "Time since epoch in seconds"

        def self.coerce_input(value, ctx)
          Time.at(Float(value))
        rescue ArgumentError
          raise GraphQL::CoercionError, 'cannot coerce to Float'
        end

        def self.coerce_result(value, ctx)
          value.to_f
        end
      end

      class Query < GraphQL::Schema::Object
        description "The query root of this schema"

        field :time, TimeType do
          argument :value, TimeType, required: false
        end

        def time(value: nil, range: nil)
          value
        end
      end

      query(Query)
    end

    let(:schema) { CustomErrorMessagesSchema2 }

    let(:query_string) {%|
      query(
        $value: Time = "a"
      ) {
        time(value: $value)
      }
    |}

    it "sets error message from a CoercionError if raised" do
      assert_equal 1, errors.length

      assert_includes errors, {
        "message"=> "cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>9}],
        "path"=>["query"],
        "extensions"=>{"code"=>"defaultValueInvalidType", "variableName"=>"value", "typeName"=>"Time"}
      }
    end
  end
end
