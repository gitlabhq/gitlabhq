# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive::OneOf do
  let(:schema) do
    this = self
    output_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "OneOfOutput"

      field :string, GraphQL::Types::String
      field :int, GraphQL::Types::Int
    end

    query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"

        field :one_of_field, output_type, null: false do
          argument :one_of_arg, this.one_of_input_object
        end.ensure_loaded

        def one_of_field(one_of_arg:)
          one_of_arg
        end
      end

    Class.new(GraphQL::Schema) do
      query(query_type)
    end
  end

  let(:one_of_input_object) do
    Class.new(GraphQL::Schema::InputObject) do
      graphql_name "OneOfInputObject"
      directive GraphQL::Schema::Directive::OneOf

      argument :int, GraphQL::Types::Int, required: false
      argument :string, GraphQL::Types::String, required: false
    end
  end

  describe "defining oneOf input objects" do
    describe "with a non-null argument" do
      let(:one_of_input_object) do
        Class.new(GraphQL::Schema::InputObject) do
          graphql_name "OneOfInputObject"
          directive GraphQL::Schema::Directive::OneOf

          argument :int, GraphQL::Types::Int, required: true # rubocop:disable GraphQL/DefaultRequiredTrue
          argument :string, GraphQL::Types::String
        end
      end

      it "raises an error" do
        error = assert_raises(ArgumentError) { schema }
        expected_message = "Argument 'OneOfInputObject.int' must be nullable because it is part of a OneOf type, add `required: false`."
        assert_equal(expected_message, error.message)
      end
    end

    describe "when an argument has a default" do
      let(:one_of_input_object) do
        Class.new(GraphQL::Schema::InputObject) do
          graphql_name "OneOfInputObject"
          directive GraphQL::Schema::Directive::OneOf

          argument :int, GraphQL::Types::Int, default_value: 1, required: false
          argument :string, GraphQL::Types::String, required: false
        end
      end

      it "raises an error" do
        error = assert_raises(ArgumentError) { schema }
        expected_message = "Argument 'OneOfInputObject.int' cannot have a default value because it is part of a OneOf type, remove `default_value: ...`."
        assert_equal(expected_message, error.message)
      end
    end
  end

  describe "execution" do
    let(:query) do
      <<~GRAPHQL
        query TestQuery($oneOfInputObject: OneOfInputObject!) {
          oneOfField(oneOfArg: $oneOfInputObject) {
            string
            int
          }
        }
      GRAPHQL
    end

    it "accepts a default value with exactly one non-null key" do
      query = <<~GRAPHQL
        query TestQuery($oneOfInputObject: OneOfInputObject = { string: "default" }) {
          oneOfField(oneOfArg: $oneOfInputObject) {
            string
            int
          }
        }
      GRAPHQL

      result = schema.execute(query)

      assert_equal({ "string" => "default", "int" => nil }, result["data"]["oneOfField"])
    end

    it "rejects a default value with multiple non-null keys" do
      query = <<~GRAPHQL
        query TestQuery($oneOfInputObject: OneOfInputObject = { string: "default", int: 2 }) {
          oneOfField(oneOfArg: $oneOfInputObject) {
            string
            int
          }
        }
      GRAPHQL

      result = schema.execute(query)

      expected_errors = ["`OneOfInputObject` is a OneOf type, so only one argument may be given (instead of 2)"]
      assert_equal(expected_errors, result["errors"].map { |e| e["message"] })
    end

    it "rejects a default value with multiple nullable keys" do
      query = <<~GRAPHQL
        query TestQuery($oneOfInputObject: OneOfInputObject = { string: "default", int: null }) {
          oneOfField(oneOfArg: $oneOfInputObject) {
            string
            int
          }
        }
      GRAPHQL

      result = schema.execute(query)

      expected_errors = ["`OneOfInputObject` is a OneOf type, so only one argument may be given (instead of 2)"]
      assert_equal(expected_errors, result["errors"].map { |e| e["message"] })
    end

    it "accepts a variable with exactly one non-null key" do
      string_result = schema.execute(query, variables: { oneOfInputObject: { string: "abc" } })
      int_result = schema.execute(query, variables: { oneOfInputObject: { int: 2 } })

      assert_equal({ "string" => "abc", "int" => nil }, string_result["data"]["oneOfField"])
      assert_equal({ "string" => nil, "int" => 2 }, int_result["data"]["oneOfField"])
    end

    it "rejects a variable with exactly one null key" do
      result = schema.execute(query, variables: { oneOfInputObject: { string: nil } })

      expected_errors = ["'OneOfInputObject' requires exactly one argument, but 'string' was `null`."]
      assert_equal(expected_errors, result["errors"].map { |e| e["extensions"]["problems"].map { |pr| pr["explanation"] } }.flatten)
    end

    it "rejects a variable with multiple non-null keys" do
      result = schema.execute(query, variables: { oneOfInputObject: { string: "abc", int: 2 } })

      expected_errors = ["'OneOfInputObject' requires exactly one argument, but 2 were provided."]
      assert_equal(expected_errors, result["errors"].map { |e| e["extensions"]["problems"].map { |pr| pr["explanation"] } }.flatten)
    end
  end
end
