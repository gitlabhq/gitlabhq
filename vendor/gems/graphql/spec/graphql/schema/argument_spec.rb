# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Argument do
  module SchemaArgumentTest
    class UnauthorizedInstrumentType < Jazz::InstrumentType
      def self.authorized?(_object, _context)
        false
      end
    end

    class ContextInput < GraphQL::Schema::InputObject
      argument :context, String
    end

    class LoadUnauthorizedInstruments < GraphQL::Schema::Resolver
      argument :ids, [ID], as: :instruments, required: false, loads: UnauthorizedInstrumentType

      def load_instruments(ids)
        ids.map { |id| context.schema.object_from_id(id, context).call }
      end

      type Integer, null: true

      def resolve(instruments:)
        instruments.size
      end
    end

    class Query < GraphQL::Schema::Object
      field :field, String do
        argument :arg, String, description: "test", comment: "test comment", required: false
        argument :deprecated_arg, String, deprecation_reason: "don't use me!", required: false

        argument :arg_with_block, String, required: false do
          description "test"
          comment "test comment"
        end
        argument :required_with_default_arg, Int, default_value: 1
        argument :aliased_arg, String, required: false, as: :renamed
        argument :prepared_arg, Int, required: false, prepare: :multiply
        argument :prepared_by_proc_arg, Int, required: false, prepare: ->(val, context) { context[:multiply_by] * val }
        argument :exploding_prepared_arg, Int, required: false, prepare: ->(val, context) do
          raise GraphQL::ExecutionError.new('boom!')
        end
        argument :unauthorized_prepared_arg, Int, required: false, prepare: ->(val, context) do
          raise GraphQL::UnauthorizedError.new('no access')
        end

        argument :keys, [String], required: false
        argument :instrument_id, ID, required: false, loads: Jazz::InstrumentType
        argument :instrument_ids, [ID], required: false, loads: Jazz::InstrumentType

        argument :unauthorized_instrument_id, ID, required: false, loads: UnauthorizedInstrumentType

        class Multiply
          def call(val, context)
            context[:multiply_by] * val
          end
        end

        argument :prepared_by_callable_arg, Int, required: false, prepare: Multiply.new
      end

      def field(**args)
        # sort the fields so that they match the output of the new interpreter
        sorted_keys = args.keys.sort
        sorted_args = {}
        sorted_keys.each  {|k| sorted_args[k] = args[k] }
        sorted_args.inspect
      end

      def multiply(val)
        context[:multiply_by] * val
      end

      field :context_arg_test, [String], null: false do
        argument :input, ContextInput
      end

      def context_arg_test(input:)
        [input.context, input.context.class, self.context.class]
      end

      field :other_unauthorized_instruments, resolver: LoadUnauthorizedInstruments
    end

    class Schema < GraphQL::Schema
      query(Query)
      lazy_resolve(Proc, :call)

      def self.object_from_id(id, ctx)
        -> { Jazz::GloballyIdentifiableType.find(id) }
      end

      def self.resolve_type(type, obj, ctx)
        -> { type } # just for `loads:`
      end
    end
  end

  describe "#keys" do
    it "is not overwritten by the 'keys' argument" do
      expected_keys = ["aliasedArg", "arg", "argWithBlock", "deprecatedArg", "explodingPreparedArg", "instrumentId", "instrumentIds", "keys", "preparedArg", "preparedByCallableArg", "preparedByProcArg", "requiredWithDefaultArg", "unauthorizedInstrumentId", "unauthorizedPreparedArg"]
      assert_equal expected_keys, SchemaArgumentTest::Query.fields["field"].arguments.keys.sort
    end
  end

  describe "#path" do
    it "includes type, field and argument names" do
      assert_equal "Query.field.argWithBlock", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].path
    end
  end

  describe "#name" do
    it "reflects camelization" do
      assert_equal "argWithBlock", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].name
    end
  end

  describe "#type" do
    let(:argument) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    it "returns the type" do
      assert_equal GraphQL::Types::String, argument.type
    end
  end

  describe "graphql definition" do
    it "calls block" do
      assert_equal "test", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].description
    end
  end

  describe "#description" do
    let(:arg) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    it "sets description" do
      arg.description "new description"
      assert_equal "new description", arg.description
    end

    it "returns description" do
      assert_equal "test", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].description
    end

    it "has an assignment method" do
      arg.description = "another new description"
      assert_equal "another new description", arg.description
    end
  end

  describe "#comment" do
    let(:arg) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }

    it "sets comment" do
      arg.comment "new comment"
      assert_equal "new comment", arg.comment
    end

    it "returns comment" do
      assert_equal "test comment", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].comment
    end

    it "has an assignment method" do
      arg.comment = "another new comment"
      assert_equal "another new comment", arg.comment
    end
  end

  describe "as:" do
    it "uses that Symbol for Ruby kwargs" do
      query_str = <<-GRAPHQL
      { field(aliasedArg: "x") }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      # Make sure it's getting the renamed symbol:
      assert_equal({renamed: "x", required_with_default_arg: 1}.inspect, res["data"]["field"])
    end
  end

  describe "prepare:" do
    it "calls the method on the field's owner" do
      query_str = <<-GRAPHQL
      { field(preparedArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal({ prepared_arg: 15, required_with_default_arg: 1}.inspect, res["data"]["field"])
    end

    it "calls the method on the provided Proc" do
      query_str = <<-GRAPHQL
      { field(preparedByProcArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal({prepared_by_proc_arg: 15, required_with_default_arg: 1 }.inspect, res["data"]["field"])
    end

    it "calls the method on the provided callable object" do
      query_str = <<-GRAPHQL
      { field(preparedByCallableArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal({prepared_by_callable_arg: 15, required_with_default_arg: 1}.inspect, res["data"]["field"])
    end

    it "handles exceptions raised by prepare" do
      query_str = <<-GRAPHQL
        { f1: field(arg: "echo"), f2: field(explodingPreparedArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      assert_equal({ 'f1' => {arg: "echo", required_with_default_arg: 1}.inspect, 'f2' => nil }, res['data'])
      assert_equal(res['errors'][0]['message'], 'boom!')
      assert_equal(res['errors'][0]['path'], ['f2'])
    end

    it "handles unauthorized exception raised by prepare" do
      query_str = <<-GRAPHQL
        { f1: field(arg: "echo"), f2: field(unauthorizedPreparedArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      assert_equal({ 'f1' => {arg: "echo", required_with_default_arg: 1}.inspect, 'f2' => nil }, res['data'])
      assert_nil(res['errors'])
    end
  end

  describe "default_value:" do
    it 'uses default_value: with no input' do
      query_str = <<-GRAPHQL
      { field }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal({required_with_default_arg: 1}.inspect, res["data"]["field"])
    end

    it 'uses provided input value' do
      query_str = <<-GRAPHQL
      { field(requiredWithDefaultArg: 2) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal({ required_with_default_arg: 2 }.inspect, res["data"]["field"])
    end

    it 'respects non-null type' do
      query_str = <<-GRAPHQL
      { field(requiredWithDefaultArg: null) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal "Argument 'requiredWithDefaultArg' on Field 'field' has an invalid value (null). Expected type 'Int!'.", res['errors'][0]['message']
    end
  end

  describe 'loads' do
    it "loads input object arguments" do
      query_str = <<-GRAPHQL
      query { field(instrumentId: "Instrument/Drum Kit") }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_equal({instrument: Jazz::Models::Instrument.new("Drum Kit", "PERCUSSION"), required_with_default_arg: 1}.inspect, res["data"]["field"])

      query_str2 = <<-GRAPHQL
      query { field(instrumentIds: ["Instrument/Organ"]) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str2)
      assert_equal({instruments: [Jazz::Models::Instrument.new("Organ", "KEYS")], required_with_default_arg: 1}.inspect, res["data"]["field"])
    end

    it "returns nil when no ID is given and `required: false`" do
      query_str = <<-GRAPHQL
      mutation($ensembleId: ID) {
        loadAndReturnEnsemble(input: {ensembleId: $ensembleId}) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, variables: { ensembleId: "Ensemble/Robert Glasper Experiment" })
      assert_equal "ROBERT GLASPER Experiment", res["data"]["loadAndReturnEnsemble"]["ensemble"]["name"]

      res2 = Jazz::Schema.execute(query_str, variables: { ensembleId: nil })
      assert_nil res2["data"]["loadAndReturnEnsemble"].fetch("ensemble")


      query_str2 = <<-GRAPHQL
      mutation {
        loadAndReturnEnsemble(input: {ensembleId: null}) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      res3 = Jazz::Schema.execute(query_str2, variables: { ensembleId: nil })
      assert_nil res3["data"]["loadAndReturnEnsemble"].fetch("ensemble")

      query_str3 = <<-GRAPHQL
      mutation {
        loadAndReturnEnsemble(input: {}) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      res4 = Jazz::Schema.execute(query_str3, variables: { ensembleId: nil })
      assert_nil res4["data"]["loadAndReturnEnsemble"].fetch("ensemble")

      query_str4 = <<-GRAPHQL
      query {
        nullableEnsemble(ensembleId: null) {
          name
        }
      }
      GRAPHQL

      res5 = Jazz::Schema.execute(query_str4)
      assert_nil res5["data"].fetch("nullableEnsemble")
    end

    it "handles unauthorized exception raised when object is resolved and returns nil" do
      query_str = <<-GRAPHQL
      query { field(unauthorizedInstrumentId: "Instrument/Drum Kit") }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_nil res["errors"]
      assert_nil res["data"].fetch("field")
    end

    it "handles applies authorization even when a custom load method is provided" do
      query_str = <<-GRAPHQL
      query { otherUnauthorizedInstruments(ids: ["Instrument/Drum Kit"]) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      assert_nil res["errors"]
      assert_nil res["data"].fetch("otherUnauthorizedInstruments")
    end
  end

  describe "deprecation_reason:" do
    let(:arg) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    let(:required_arg) {  SchemaArgumentTest::Query.fields["field"].arguments["requiredWithDefaultArg"] }

    it "sets deprecation reason" do
      arg.deprecation_reason "new deprecation reason"
      assert_equal "new deprecation reason", arg.deprecation_reason
    end

    it "returns the deprecation reason" do
      assert_equal "don't use me!", SchemaArgumentTest::Query.fields["field"].arguments["deprecatedArg"].deprecation_reason
    end

    it "has an assignment method" do
      arg.deprecation_reason = "another new deprecation reason"
      assert_equal "another new deprecation reason", arg.deprecation_reason
      assert_equal 1, arg.directives.size
      arg.deprecation_reason = "something else"
      assert_equal "something else", arg.deprecation_reason
      assert_equal 1, arg.directives.size
      arg.deprecation_reason = nil
      assert_nil arg.deprecation_reason
      assert_equal 0, arg.directives.size
    end

    it "disallows deprecating required arguments in the constructor" do
      err = assert_raises ArgumentError do
        Class.new(GraphQL::Schema::InputObject) do
          graphql_name 'MyInput'
          argument :foo, String, deprecation_reason: "Don't use me"
        end
      end
      assert_equal "Required arguments cannot be deprecated: MyInput.foo.", err.message
    end

    it "disallows deprecating required arguments in deprecation_reason=" do
      assert_raises ArgumentError do
        required_arg.deprecation_reason = "Don't use me"
      end
    end

    it "disallows deprecating required arguments in deprecation_reason" do
      assert_raises ArgumentError do
        required_arg.deprecation_reason("Don't use me")
      end
    end

    it "disallows deprecated required arguments whose type is a string" do
      input_obj = Class.new(GraphQL::Schema::InputObject) do
        graphql_name 'MyInput2'
        argument :foo, "String!", required: false, deprecation_reason: "Don't use me"
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :f, String do
          argument :arg, input_obj, required: false
        end
      end

      err = assert_raises ArgumentError do
        Class.new(GraphQL::Schema) do
          query(query_type)
        end.to_definition
      end

      assert_equal "Required arguments cannot be deprecated: MyInput2.foo.", err.message
    end
  end

  describe "invalid input types" do
    class InvalidArgumentTypeSchema < GraphQL::Schema
      class InvalidArgumentType < GraphQL::Schema::Object
      end

      class InvalidArgumentObject < GraphQL::Schema::Object
        field :invalid, Boolean, null: false do
          argument :object_ref, InvalidArgumentType, required: false
        end
      end

      class InvalidLazyArgumentObject < GraphQL::Schema::Object
        field :invalid, Boolean, null: false do
          argument :lazy_object_ref, "InvalidArgumentTypeSchema::InvalidArgumentType", required: false
        end
      end
    end

    it "rejects them" do
      err = assert_raises ArgumentError do
        Class.new(InvalidArgumentTypeSchema) do
          query(InvalidArgumentTypeSchema::InvalidArgumentObject)
        end.to_definition
      end

      expected_message = "Invalid input type for InvalidArgumentObject.invalid.objectRef: InvalidArgument. Must be scalar, enum, or input object, not OBJECT."
      assert_equal expected_message, err.message

      err = assert_raises ArgumentError do
        Class.new(InvalidArgumentTypeSchema) do
          query(InvalidArgumentTypeSchema::InvalidLazyArgumentObject)
        end.to_definition
      end

      expected_message = "Invalid input type for InvalidLazyArgumentObject.invalid.lazyObjectRef: InvalidArgument. Must be scalar, enum, or input object, not OBJECT."
      assert_equal expected_message, err.message
    end
  end

  describe "validating default values" do
    it "raises when field argument default values are invalid" do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :f1, Integer, null: false do
          argument :arg1, Integer, default_value: nil
        end
      end

      err = assert_raises GraphQL::Schema::Argument::InvalidDefaultValueError do
        Class.new(GraphQL::Schema) do
          query(query_type)
        end.to_definition
      end
      expected_message = "`Query.f1.arg1` has an invalid default value: `nil` isn't accepted by `Int!`; update the default value or the argument type."
      assert_equal expected_message, err.message
    end

    it "raises when input argument default values are invalid" do
      input_obj = Class.new(GraphQL::Schema::InputObject) do
        graphql_name "InputObj"
        argument :arg1, [String, null: false], default_value: [nil], required: false
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :f1, Integer, null: false do
          argument :input, input_obj
        end
      end

      err = assert_raises GraphQL::Schema::Argument::InvalidDefaultValueError do
        Class.new(GraphQL::Schema) do
          query(query_type)
        end.to_definition
      end

      expected_message = "`InputObj.arg1` has an invalid default value: `[nil]` isn't accepted by `[String!]`; update the default value or the argument type."
      assert_equal expected_message, err.message
    end

    it "raises when directive argument default values are invalid" do
      lang = Class.new(GraphQL::Schema::Enum) do
        graphql_name "Language"
        value "EN"
        value "JA"
      end

      localize = Class.new(GraphQL::Schema::Directive) do
        graphql_name "localize"
        locations GraphQL::Schema::Directive::FIELD
        argument :lang, lang, default_value: "ZH", required: false
      end

      err = assert_raises GraphQL::Schema::Argument::InvalidDefaultValueError do
        Class.new(GraphQL::Schema) do
          directive(localize)
        end.to_definition
      end

      expected_message = "`@localize.lang` has an invalid default value: `\"ZH\"` isn't accepted by `Language`; update the default value or the argument type."
      assert_equal expected_message, err.message
    end

    it "raises when parsing a schema from a string" do
      schema_str = <<-GRAPHQL
      type Query {
        f1(arg1: Int! = null): Int!
      }
      GRAPHQL

      err = assert_raises GraphQL::Schema::Argument::InvalidDefaultValueError do
        GraphQL::Schema.from_definition(schema_str)
      end
      expected_message = "`Query.f1.arg1` has an invalid default value: `nil` isn't accepted by `Int!`; update the default value or the argument type."
      assert_equal expected_message, err.message

      directive_schema_str = <<-GRAPHQL
      enum Language {
        EN
        JA
      }
      directive @localize(lang: Language = "ZH") on FIELD

      type Query {
        f1: Int
      }
      GRAPHQL


      err2 = assert_raises GraphQL::Schema::Argument::InvalidDefaultValueError do
        GraphQL::Schema.from_definition(directive_schema_str).to_definition
      end
      expected_message = "`@localize.lang` has an invalid default value: `\"ZH\"` isn't accepted by `Language`; update the default value or the argument type."
      assert_equal expected_message, err2.message

      input_obj_schema_str = <<-GRAPHQL
      input InputObj {
        arg1: [String!] = [null]
      }

      type Query {
        f1(arg1: InputObj): Int
      }
      GRAPHQL


      err3 = assert_raises GraphQL::Schema::Argument::InvalidDefaultValueError do
        GraphQL::Schema.from_definition(input_obj_schema_str)
      end
      expected_message = "`InputObj.arg1` has an invalid default value: `[nil]` isn't accepted by `[String!]`; update the default value or the argument type."
      assert_equal expected_message, err3.message
    end
  end

  it "works with arguments named context" do
    res = SchemaArgumentTest::Schema.execute("{ contextArgTest(input: { context: \"abc\" }) }")
    assert_equal ["abc", "String", "GraphQL::Query::Context"], res["data"]["contextArgTest"]
  end

  describe "required: :nullable" do
    class RequiredNullableSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :echo, String do
          argument :str, String, required: :nullable
        end

        def echo(str:)
          str
        end
      end

      query(Query)
    end

    it "requires a value, even if it's null" do
      res = RequiredNullableSchema.execute('{ echo(str: "ok") }')
      assert_equal "ok", res["data"]["echo"]
      res = RequiredNullableSchema.execute('{ echo(str: null) }')
      assert_nil res["data"].fetch("echo")
      res = RequiredNullableSchema.execute('{ echo }')
      assert_equal ["echo must include the following argument: str."], res["errors"].map { |e| e["message"] }
    end
  end

  describe "replace_null_with_default: true" do
    class ReplaceNullWithDefaultSchema < GraphQL::Schema
      class Add < GraphQL::Schema::Resolver
        argument :left, Integer, required: false, default_value: 5, replace_null_with_default: true
        argument :right, Integer
        type Integer, null: false

        def resolve(left:, right:)
          right + left
        end
      end

      class AddInput < GraphQL::Schema::InputObject
        argument :left, Integer, required: false, default_value: 5, replace_null_with_default: true
        argument :right, Integer
      end

      class Query < GraphQL::Schema::Object
        field :add1, Integer do
          argument :left, Integer, required: false, default_value: 5, replace_null_with_default: true
          argument :right, Integer
        end

        def add1(left:, right:)
          left + right
        end

        field :add2, resolver: Add

        field :add3, Integer do
          argument :input, AddInput
        end

        def add3(input:)
          input[:left] + input[:right]
        end
      end
      query(Query)
    end

    it "works for fields, resolvers, and input objects" do
      res1 = ReplaceNullWithDefaultSchema.execute("{ r1: add1(left: null, right: 2) r2: add1(right: 0)}")
      assert_equal 7, res1["data"]["r1"]
      assert_equal 5, res1["data"]["r2"]

      res2 = ReplaceNullWithDefaultSchema.execute("{ r1: add2(left: null, right: 1) r2: add2(right: 3) }")
      assert_equal 6, res2["data"]["r1"]
      assert_equal 8, res2["data"]["r2"]

      res3 = ReplaceNullWithDefaultSchema.execute("{ r1: add3(input: { left: null, right: 5 }) r2: add3(input: { right: 6 }) }")
      assert_equal 10, res3["data"]["r1"]
      assert_equal 11, res3["data"]["r2"]
    end
  end

  it "can get default_value and prepare from method calls in the config block" do
    type = Class.new(GraphQL::Schema::Object) do
      field :f, String do
        argument :arg, String do
          default_value "blah"
          prepare -> { :stuff }
        end
      end
    end

    arg = type.get_field("f").get_argument("arg")
    assert_equal "blah", arg.default_value
    assert_equal :stuff, arg.prepare.call
  end

  describe "multiple argument definitions with default values" do
    class MultipleArgumentDefaultValuesSchema < GraphQL::Schema
      use GraphQL::Schema::Warden if ADD_WARDEN
      class BaseArgument < GraphQL::Schema::Argument
        def initialize(*args, use_if:, **kwargs, &block)
          @use_if = use_if
          super(*args, **kwargs, &block)
        end

        def visible?(ctx)
          ctx[:use_if] == @use_if
        end
      end

      class BaseField < GraphQL::Schema::Field
        argument_class BaseArgument
      end

      class Query < GraphQL::Schema::Object
        field_class BaseField

        field :echo, String do
          argument :input, String, required: false, default_value: "argument-default-1", use_if: :visible_1
          argument :input, String, required: false, default_value: "argument-default-2", use_if: :visible_2
          argument :input, String, required: false, default_value: nil, use_if: :visible_3
        end

        def echo(input: "method-default")
          input || "dynamic-fallback"
        end
      end

      query(Query)
    end

    def get_echo_for(use_if)
      res = MultipleArgumentDefaultValuesSchema.execute("{ echo }", context: { use_if: use_if })
      res["data"]["echo"]
    end

    it "uses the default value from the matching argument if there is one" do
      assert_equal "argument-default-1", get_echo_for(:visible_1)
      assert_equal "argument-default-2", get_echo_for(:visible_2)
      assert_equal "dynamic-fallback", get_echo_for(:visible_3)
      assert_equal "method-default", get_echo_for(:visible_4) # no match
    end
  end

  describe "multiple argument validations with rescue_from" do
    let(:schema) do
      Class.new(GraphQL::Schema) do
        rescue_from(StandardError) do |exception, _obj, _args, _context, _field|
          raise exception
        end

        query_type = Class.new(GraphQL::Schema::Object) do
          graphql_name 'TestQueryType'

          field :test, Integer, null: false do
            argument :a, Integer, validates: { numericality: { greater_than_or_equal_to: 1 } }
            argument :b, Integer, validates: { numericality: { greater_than_or_equal_to: 1 } }
          end

          def test; end
        end

        query(query_type)
        lazy_resolve(Proc, :call)
      end
    end

    it 'validates both arguments' do
      expected_errors = [
        {
          "message"=>"a must be greater than or equal to 1",
          "locations"=>[{ "line"=>1, "column"=>3 }],
          "path"=>["test"]
        },
        {
          "message"=>"b must be greater than or equal to 1",
          "locations"=>[{"line"=>1, "column"=>3}],
          "path"=>["test"]
        }
      ]
      query = "{ test(a: -4, b: -5) }"

      assert_equal expected_errors, schema.execute(query).to_h['errors']
    end
  end

  describe "default values for non-null input object arguments when not present in variables" do
    class InputObjectArgumentWithDefaultValueSchema < GraphQL::Schema
      class Add < GraphQL::Schema::Resolver
        class AddInput < GraphQL::Schema::InputObject
          argument :a, Integer
          argument :b, Integer
          argument :c, Integer, default_value: 10
        end

        argument :input, AddInput
        type(Integer, null: false)

        def resolve(input:)
          input[:a] + input[:b] + input[:c]
        end
      end
      class Query < GraphQL::Schema::Object
        field :add, resolver: Add
      end
      query(Query)
    end

    it "uses the default value" do
      res1 = InputObjectArgumentWithDefaultValueSchema.execute("{ add(input: { a: 1, b: 2 })}")
      assert_equal 13, res1["data"]["add"]

      res2 = InputObjectArgumentWithDefaultValueSchema.execute("query Add($input: AddInput!) { add(input: $input) }", variables: { input: { a: 1, b: 4 } })
      assert_equal 15, res2["data"]["add"]
    end
  end
end
