# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::Validator do
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: Dummy::Schema) }
  let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }
  let(:validate) { true }
  let(:errors) { validator.validate(query, validate: validate)[:errors].map(&:to_h) }

  describe "tracing" do
    let(:query_string) { "{ t: __typename }"}
    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, context: {tracers: [TestTracing]}) }

    it "emits a trace" do
      traces = TestTracing.with_trace do
        validator.validate(query)
      end

      if USING_C_PARSER
        assert_equal 3, traces.length
      else
        assert_equal 2, traces.length
      end
      validate_trace = traces.last
      assert_equal "validate", validate_trace[:key]
      assert_equal true, validate_trace[:validate]
      assert_instance_of GraphQL::Query, validate_trace[:query]
      assert_instance_of Hash, validate_trace[:result]
    end
  end

  describe "error format" do
    let(:query_string) { "{ cheese(id: $undefinedVar) { source } }" }
    let(:document) { GraphQL.parse(query_string, filename: "not_a_real.graphql") }
    let(:query) { GraphQL::Query.new(Dummy::Schema, nil, document: document) }

    it "includes message, locations, and fields keys" do
      expected_errors = [{
        "message" => "Variable $undefinedVar is used by anonymous query but not declared",
        "locations" => [{"line" => 1, "column" => 14, "filename" => "not_a_real.graphql"}],
        "path" => ["query", "cheese", "id"],
        "extensions"=>{"code"=>"variableNotDefined", "variableName"=>"undefinedVar"}
      }]
      assert_equal expected_errors, errors
    end
  end

  describe "validation order" do
    let(:document) { GraphQL.parse(query_string)}

    describe "fields & arguments" do
      let(:query_string) { %|
        query getCheese($id: Int!) {
          cheese(id: $undefinedVar, bogusArg: true) {
            source,
            nonsenseField,
            id(nonsenseArg: 1)
            bogusField(bogusArg: true)
          }

          otherCheese: cheese(id: $id) {
            source,
          }
        }
      |}

      it "handles args on invalid fields" do
        # nonsenseField, nonsenseArg, bogusField, bogusArg, undefinedVar
        assert_equal(5, errors.length)
      end

      describe "when validate: false" do
        let(:validate) { false }

        it "skips validation" do
          assert_equal 0, errors.length
        end
      end
    end

    describe "infinite fragments" do
      let(:query_string) { %|
        query getCheese {
          cheese(id: 1) {
            ... cheeseFields
          }
        }
        fragment cheeseFields on Cheese {
          ... on Cheese {
            id, ... cheeseFields
          }
        }
      |}

      it "handles infinite fragment spreads" do
        assert_equal(1, errors.length)
      end

      describe "nested spreads" do
        let(:query_string) {%|
        {
          allEdible {
            ... on Cheese {
              ... cheeseFields
            }
          }
        }

        fragment cheeseFields on Cheese {
          similarCheese(source: COW) {
            similarCheese(source: COW) {
              ... cheeseFields
            }
          }
        }
        |}

        it "finds an error on the nested spread" do
          expected = [
            {
              "message"=>"Fragment cheeseFields contains an infinite loop",
              "locations"=>[{"line"=>10, "column"=>9}],
              "path"=>["fragment cheeseFields"],
              "extensions"=>{"code"=>"infiniteLoop", "fragmentName"=>"cheeseFields"}
            }
          ]
          assert_equal(expected, errors)
        end
      end
    end

    describe "fragment spreads with no selections" do
      let(:query_string) {%|
        query SimpleQuery {
          cheese(id: 1) {
            # OK:
            ... {
              id
            }
            # NOT OK:
            ...cheeseFields
          }
        }
      |}
      it "marks an error" do
        assert_equal(1, errors.length)
      end
    end

    describe "fragments with no names" do
      let(:query_string) {%|
        fragment on Cheese {
          id
          flavor
        }
      |}
      it "marks an error" do
        assert_equal(1, errors.length)
      end
    end
  end

  describe "validation timeout" do
    module StubValidationTimeout
      def on_operation_definition(node, parent)
        raise Timeout::Error.new
      end
    end
    let(:rules) {
      [
        StubValidationTimeout
      ]
    }
    let(:validator) { GraphQL::StaticValidation::Validator.new(schema: Dummy::Schema, rules: rules) }
    let(:query_string) { "{ t: __typename }"}
    let(:errors) { validator.validate(query, validate: validate, timeout: 0.1)[:errors].map(&:to_h) }

    it "aborts and return error" do
      expected_errors = [{
        "message" => "Timeout on validation of query",
        "locations" => [],
        "extensions"=>{"code"=>"validationTimeout"}
      }]
      assert_equal expected_errors, errors
    end
  end

  describe "Custom ruleset" do
    let(:query_string) { "
        fragment Thing on Cheese {
          __typename
          similarCheese(source: COW)
        }
      "
    }

    let(:rules) {
      # This is from graphql-client, eg
      # https://github.com/github/graphql-client/blob/c86fc05d7eba2370452592bb93572caced4123af/lib/graphql/client.rb#L168
      GraphQL::StaticValidation::ALL_RULES - [
        GraphQL::StaticValidation::FragmentsAreUsed,
        GraphQL::StaticValidation::FieldsHaveAppropriateSelections
      ]
    }
    let(:validator) { GraphQL::StaticValidation::Validator.new(schema: Dummy::Schema, rules: rules) }

    it "runs the specified rules" do
      assert_equal 0, errors.size
    end
  end
end
