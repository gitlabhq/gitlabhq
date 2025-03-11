# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Scalar do
  describe ".path" do
    it "is the name" do
      assert_equal "String", GraphQL::Types::String.path
    end
  end

  describe "in queries" do
    it "becomes output" do
      query_str = <<-GRAPHQL
      {
        find(id: "Musician/Herbie Hancock") {
          ... on Musician {
            name
            favoriteKey
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal "B♭", res["data"]["find"]["favoriteKey"]
    end

    it "handles infinity values" do
      query_str = <<-GRAPHQL
      {
        find(id: 9999.0e9999) {
          __typename
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_errors = ["Argument 'id' on Field 'find' has an invalid value. Expected type 'ID!'."]
      assert_equal expected_errors, res["errors"].map { |e| e["message"] }
    end

    it "can be input" do
      query_str = <<-GRAPHQL
      {
        inspectKey(key: "F♯") {
          root
          isSharp
          isFlat
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      key_info = res["data"]["inspectKey"]
      assert_equal "F", key_info["root"]
      assert_equal true, key_info["isSharp"]
      assert_equal false, key_info["isFlat"]
    end

    it "can be nested JSON" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: {foo: [{bar: "baz"}]})
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal({"foo" => [{"bar" => "baz"}]}, res["data"]["echoJson"])
    end

    it "can be a JSON array" do
      query_str = <<-GRAPHQL
      {
        echoFirstJson(input: [{foo: "bar"}, {baz: "boo"}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal({"foo" => "bar"}, res["data"]["echoFirstJson"])
    end

    it "can be a JSON array even if the GraphQL type is not an array" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: [{foo: "bar"}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal([{"foo" => "bar"}], res["data"]["echoJson"])
    end

    it "can be JSON with a nested enum" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: [{foo: WOODWIND}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal([{"foo" => "WOODWIND"}], res["data"]["echoJson"])
    end

    it "cannot be JSON with a nested variable" do
      query_str = <<-GRAPHQL
      {
        echoJson(input: [{foo: $var}])
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_includes(res["errors"][0]["message"], "Argument 'input' on Field 'echoJson' has an invalid value")
    end
  end

  describe "raising CoercionError" do
    class CoercionErrorSchema < GraphQL::Schema
      class CustomScalar < GraphQL::Schema::Scalar
        def self.coerce_input(val, ctx)
          raise GraphQL::CoercionError, "#{val.inspect} can't be Custom value"
        end
      end

      class Query < GraphQL::Schema::Object
        field :f1, String do
          argument :arg, CustomScalar
        end
      end

      query(Query)
    end

    it "makes a nice validation error" do
      result = CoercionErrorSchema.execute("{ f1(arg: \"a\") }")
      expected_error = {
        "message" => "\"a\" can't be Custom value",
        "locations" => [{"line"=>1, "column"=>3}],
        "path" => ["query", "f1", "arg"],
        "extensions" => {
          "code"=>"argumentLiteralsIncompatible",
          "typeName"=>"CoercionError"
        }
      }
      assert_equal [expected_error], result["errors"]
    end
  end


  describe "validate_input with good input" do
    let(:result) { GraphQL::Types::Int.validate_input(150, GraphQL::Query::NullContext.instance) }

    it "returns a valid result" do
      assert(result.valid?)
    end
  end

  describe "validate_input with bad input" do
    let(:result) { GraphQL::Types::Int.validate_input("bad num", GraphQL::Query::NullContext.instance) }

    it "returns an invalid result for bad input" do
      assert(!result.valid?)
    end

    it "has one problem" do
      assert_equal(result.problems.length, 1)
    end

    it "has the correct explanation" do
      assert(result.problems[0]["explanation"].include?("Could not coerce value"))
    end

    it "has an empty path" do
      assert(result.problems[0]["path"].empty?)
    end
  end

  describe "Custom scalars" do
    let(:custom_scalar) {
      Class.new(GraphQL::Schema::Scalar) do
        graphql_name "BigInt"
        def self.coerce_input(value, _ctx)
          value =~ /\d+/ ? Integer(value) : nil
        end

        def self.coerce_result(value, _ctx)
          value.to_s
        end
      end
    }
    let(:bignum) { 2 ** 128 }

    it "is not a default scalar" do
      assert_equal(false, custom_scalar.default_scalar?)
    end

    it "coerces nil into nil" do
      assert_nil(custom_scalar.coerce_isolated_input(nil))
    end

    it "coerces input into objects" do
      assert_equal(bignum, custom_scalar.coerce_isolated_input(bignum.to_s))
    end

    it "coerces result value for serialization" do
      assert_equal(bignum.to_s, custom_scalar.coerce_isolated_result(bignum))
    end

    describe "custom scalar errors" do
      let(:result) { custom_scalar.validate_input("xyz", GraphQL::Query::NullContext.instance) }

      it "returns an invalid result" do
        assert !result.valid?
        assert_equal 'Could not coerce value "xyz" to BigInt', result.problems[0]["explanation"]
      end
    end
  end

  it "handles coercing null" do
    class CoerceNullSchema < GraphQL::Schema
      class CustomScalar < GraphQL::Schema::Scalar
        class << self
          def coerce_input(input_value, _context)
            raise GraphQL::CoercionError, "Invalid value: #{input_value.inspect}"
          end
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :hello, String do
          argument :input, CustomScalar, required: false
        end

        def hello(input: nil)
          "hello world"
        end
      end

      query(QueryType)
    end
    result = CoerceNullSchema.execute('{ hello(input: 5) }')
    assert_equal(["Invalid value: 5"], result["errors"].map { |err| err["message"] })

    null_input_result = CoerceNullSchema.execute('{ hello(input: null) }')
    assert_equal(["Invalid value: nil"], null_input_result["errors"].map { |err| err["message"] })
  end
end
