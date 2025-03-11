# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Resolver do
  module ResolverTest
    class SpecialError < StandardError
      attr_accessor :id
    end

    class LazyBlock
      def initialize(&block)
        @get_value = block
      end

      def value
        @get_value.call
      end
    end

    class BaseResolver < GraphQL::Schema::Resolver
    end

    class Resolver1 < BaseResolver
      argument :value, Integer, required: false
      type [Integer, null: true], null: false

      def initialize(object:, context:, field:)
        super
        if defined?(@value)
          raise "The instance should start fresh"
        end
        @value = [100]
      end

      def resolve(value: nil)
        @value << value
        @value
      end
    end

    class Resolver2 < Resolver1
      argument :extra_value, Integer

      def resolve(extra_value:, **_rest)
        value = super(**_rest)
        value << extra_value
        value
      end
    end

    class Resolver3 < Resolver1
    end

    class Resolver4 < BaseResolver
      type Integer, null: false

      description "Adds object.value to ast_node.name.size"

      extras [:ast_node]
      def resolve(ast_node:)
        object.value + ast_node.name.size
      end
    end

    class ResolverWithPath < BaseResolver
      type String, null: false

      extras [:path]
      def resolve(path:)
        path.inspect
      end
    end

    class Resolver5 < Resolver4
    end

    class Resolver6 < Resolver1
      type Integer, null: false

      def resolve
        self.class.complexity
      end
    end

    class Resolver7 < Resolver6
      complexity 2
    end

    class Resolver8 < Resolver7
    end

    class GreetingExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, **rest)
        name = yield(object, arguments)
        "#{options[:greeting]}, #{name}!"
      end
    end

    class ResolverWithExtension < BaseResolver
      type String, null: false

      extension GreetingExtension, greeting: "Hi"

      def resolve
        "Robert"
      end
    end

    class PrepResolver1 < BaseResolver
      argument :int, Integer

      def load_int(i)
        i * 10
      end

      type Integer, null: false

      def resolve(int:)
        int
      end

      private

      def check_for_magic_number(int)
        if int == 13
          raise GraphQL::ExecutionError, "13 is unlucky!"
        elsif int > 99
          raise GraphQL::UnauthorizedError, "Top secret big number: #{int}"
        else
          int
        end
      end
    end

    class PrepResolver2 < PrepResolver1
      def load_int(i)
        LazyBlock.new {
          super - 35
        }
      end
    end

    class PrepResolver3 < PrepResolver1
      type Integer, null: true

      def load_int(i)
        check_for_magic_number(i)
      end
    end

    class PrepResolver4 < PrepResolver3
      def load_int(i)
        LazyBlock.new {
          super
        }
      end
    end

    class PrepResolver5 < PrepResolver1
      type Integer, null: true

      def ready?(int:)
        check_for_magic_number(int)
      end
    end

    class PrepResolver6 < PrepResolver5
      def ready?(**args)
        LazyBlock.new {
          super
        }
      end
    end

    class PrepResolver7 < GraphQL::Schema::Mutation
      argument :int, Integer
      field :errors, [String]
      field :int, Integer

      def ready?(int:)
        if int == 13
          return false, { errors: ["Bad number!"] }
        else
          true
        end
      end

      def resolve(int:)
        { int: int }
      end
    end

    class ResolverWithFalseyValueReady < BaseResolver
      type Boolean, null: true

      def ready?
        return false, false
      end

      def resolve
        true
      end
    end

    class ResolverWithInvalidReady < GraphQL::Schema::Mutation
      argument :int, Integer
      field :int, Integer

      def ready?(**args)
        return [1,2,3]
      end

      def resolve(int:)
        { int: int }
      end
    end

    module HasValue
      include GraphQL::Schema::Interface
      field :value, Integer, null: false
      def self.resolve_type(obj, ctx)
        LazyBlock.new {
          if obj.is_a?(Integer)
            IntegerWrapper
          elsif obj == :resolve_type_as_wrong_type
            GraphQL::Types::String
          else
            raise "Unexpected: #{obj.inspect}"
          end
        }
      end
    end

    class IntegerWrapper < GraphQL::Schema::Object
      implements HasValue
      field :value, Integer, null: false, method: :itself

      def self.authorized?(value, ctx)
        if ctx[:max_value] && value > ctx[:max_value]
          false
        else
          true
        end
      end
    end

    class PrepResolver9 < BaseResolver
      argument :int_id, ID, loads: HasValue
      # Make sure the lazy object is resolved properly:
      type HasValue, null: true
      def object_from_id(type, id, ctx)
        # Make sure a lazy object is handled appropriately
        LazyBlock.new {
          # Make sure that the right type ends up here
          id.to_i + type.graphql_name.length
        }
      end

      def resolve(int:)
        int * 3
      end

      def unauthorized_object(err)
        if context[:use_replacement]
          context[:use_replacement]
        else
          raise GraphQL::ExecutionError, "Unauthorized #{err.type.graphql_name} loaded for #{err.context[:current_path].join(".")}"
        end
      end
    end

    class PrepResolver9Array < BaseResolver
      argument :int_ids, [ID], loads: HasValue, as: :ints
      # Make sure the lazy object is resolved properly:
      type [HasValue], null: false
      def object_from_id(type, id, ctx)
        # Make sure a lazy object is handled appropriately
        LazyBlock.new {
          # Make sure that the right type ends up here
          id.to_i + type.graphql_name.length
        }
      end

      def resolve(ints:)
        ints.map { |int| int * 3}
      end
    end

    class ResolverWithErrorHandler < BaseResolver
      argument :int, ID, loads: HasValue
      type HasValue, null: true
      def object_from_id(type, id, ctx)
        LazyBlock.new {
          if id == "failed_to_find"
            nil
          elsif id == "resolve_type_as_wrong_type"
            :resolve_type_as_wrong_type
          else
            id.length
          end
        }
      end

      def resolve(int:)
        int ? int * 4 : nil
      end

      def load_application_object_failed(err)
        if (next_obj = err.context[:fallback_object])
          next_obj
        elsif err.context[:return_nil_on_load_failed]
          nil
        elsif err.context[:reraise_special_error]
          spec_err = SpecialError.new
          spec_err.id = err.id
          raise(spec_err)
        else
          raise(GraphQL::ExecutionError.new("ResolverWithErrorHandler failed for id: #{err.id.inspect} (#{err.object.inspect}) (#{err.class.name})"))
        end
      end
    end

    class PrepResolver10 < BaseResolver
      argument :int1, Integer
      argument :int2, Integer, as: :integer_2
      type Integer, null: true
      def authorized?(int1:, integer_2:)
        if int1 + integer_2 > context[:max_int]
          raise GraphQL::ExecutionError, "Inputs too big"
        elsif context[:min_int] && (int1 + integer_2 < context[:min_int])
          false
        else
          true
        end
      end

      def resolve(int1:, integer_2:)
        int1 + integer_2
      end
    end

    class PrepResolver11 < PrepResolver10
      def authorized?(int1:, integer_2:)
        LazyBlock.new { super(int1: int1 * 2, integer_2: integer_2) }
      end
    end

    class ResolverWithFalseyValueAuthorized < BaseResolver
      type Boolean, null: true

      def authorized?
        return false, false
      end

      def resolve
        true
      end
    end

    class PrepResolver12 < GraphQL::Schema::Mutation
      argument :int1, Integer
      argument :int2, Integer
      field :error_messages, [String]
      field :value, Integer
      def authorized?(int1:, int2:)
        if int1 + int2 > context[:max_int]
          return false, { error_messages: ["Inputs must be less than #{context[:max_int]} (but you provided #{int1 + int2})"] }
        else
          true
        end
      end

      def resolve(int1:, int2:)
        { value: int1 + int2 }
      end
    end

    class PrepResolver13 < PrepResolver12
      def authorized?(int1:, int2:)
        # Increment the numbers so we can be sure they're passing through here
        LazyBlock.new { super(int1: int1 + 1, int2: int2 + 1) }
      end
    end

    class PrepResolver14 < GraphQL::Schema::RelayClassicMutation
      field :number, Integer, null: false

      def authorized?
        true
      end

      def resolve
        { number: 1 }
      end
    end

    class ResolverWithAuthArgs < GraphQL::Schema::RelayClassicMutation
      argument :number_s, String, prepare: ->(v, ctx) { v.to_i }
      argument :loads_id, ID, loads: IntegerWrapper

      field :result, Integer, null: false

      def authorized?(**_args)
        if arguments[:number_s] == 1 && arguments[:loads] == 1
          true
        else
          raise GraphQL::ExecutionError, "Auth failed (#{arguments[:number_s].inspect})"
        end
      end

      def resolve(number_s:, loads:)
        { result: number_s + loads }
      end
    end

    class MutationWithNullableLoadsArgument < GraphQL::Schema::Mutation
      argument :label_id, ID, required: false, loads: HasValue
      argument :label_ids, [ID], required: false, loads: HasValue

      field :inputs, String, null: false

      def resolve(**inputs)
        {
          inputs: JSON.dump(inputs)
        }
      end
    end

    class MutationWithRequiredLoadsArgument < GraphQL::Schema::Mutation
      argument :label_id, ID, loads: HasValue

      field :inputs, String, null: false

      def resolve(**inputs)
        {
          inputs: JSON.dump(inputs)
        }
      end
    end

    class Mutation < GraphQL::Schema::Object
      field :mutation_with_nullable_loads_argument, mutation: MutationWithNullableLoadsArgument
      field :mutation_with_required_loads_argument, mutation: MutationWithRequiredLoadsArgument
      field :resolver_with_invalid_ready, resolver: ResolverWithInvalidReady
    end

    class Query < GraphQL::Schema::Object
      class CustomField < GraphQL::Schema::Field
        def resolve_field(*args)
          value = super
          if @name == "resolver3"
            value << -1
          end
          value
        end

        def resolve(*)
          value = super
          if @name == "resolver3"
            value << -1
          end
          value
        end
      end

      field_class(CustomField)

      field :resolver_1, resolver: Resolver1
      field :resolver_2, resolver: Resolver2
      field :resolver_3, resolver: Resolver3
      field :resolver_3_again, resolver: Resolver3, description: "field desc"
      field :resolver_4, "Positional description", resolver: Resolver4
      field :resolver_5, resolver: Resolver5
      field :resolver_6, resolver: Resolver6
      field :resolver_7, resolver: Resolver7
      field :resolver_8, resolver: Resolver8
      field :resolver_with_extension, resolver: ResolverWithExtension
      field :resolver_with_path, resolver: ResolverWithPath

      field :prep_resolver_1, resolver: PrepResolver1
      field :prep_resolver_2, resolver: PrepResolver2
      field :prep_resolver_3, resolver: PrepResolver3
      field :prep_resolver_4, resolver: PrepResolver4
      field :prep_resolver_5, resolver: PrepResolver5
      field :prep_resolver_6, resolver: PrepResolver6
      field :prep_resolver_7, resolver: PrepResolver7
      field :prep_resolver_9, resolver: PrepResolver9
      field :prep_resolver_9_array, resolver: PrepResolver9Array
      field :prep_resolver_10, resolver: PrepResolver10
      field :prep_resolver_11, resolver: PrepResolver11
      field :prep_resolver_12, resolver: PrepResolver12
      field :prep_resolver_13, resolver: PrepResolver13
      field :prep_resolver_14, resolver: PrepResolver14
      field :resolver_with_falsey_value_ready, resolver: ResolverWithFalseyValueReady
      field :resolver_with_falsey_value_authorized, resolver: ResolverWithFalseyValueAuthorized
      field :resolver_with_auth_args, resolver: ResolverWithAuthArgs
      field :resolver_with_error_handler, resolver: ResolverWithErrorHandler
    end

    class Schema < GraphQL::Schema
      query(Query)
      mutation(Mutation)
      lazy_resolve LazyBlock, :value
      orphan_types IntegerWrapper

      def self.object_from_id(id, ctx)
        if id == "invalid"
          nil
        else
          1
        end
      end

      def self.resolve_type(type, obj, ctx)
        type # This will work for loaded objects well enough
      end

      rescue_from SpecialError do |err|
        raise GraphQL::ExecutionError, "A special error was raised from #{err.id.inspect}"
      end
    end
  end

  def exec_query(*args, **kwargs)
    ResolverTest::Schema.execute(*args, **kwargs)
  end

  it "can access self.arguments inside authorized?" do
    res = exec_query("{ resolverWithAuthArgs(input: { numberS: \"1\", loadsId: 1 }) { result } }")
    assert_equal 2, res["data"]["resolverWithAuthArgs"]["result"]

    # Test auth failure:
    res = exec_query("{ resolverWithAuthArgs(input: { numberS: \"2\", loadsId: 1 }) { result } }")
    assert_equal ["Auth failed (2)"], res["errors"].map { |e| e["message"] }
  end

  describe ".path" do
    it "is the name" do
      assert_equal "Resolver1", ResolverTest::Resolver1.path
    end

    it "is used for arguments and fields" do
      assert_equal "Resolver1.value", ResolverTest::Resolver1.arguments["value"].path
      assert_equal "PrepResolver7.int", ResolverTest::PrepResolver7.fields["int"].path
    end

    it "works on instances" do
      r = ResolverTest::Resolver1.new(object: nil, context: GraphQL::Query::NullContext.instance, field: nil)
      assert_equal "Resolver1", r.path
    end
  end

  it "gets initialized for each resolution" do
    # State isn't shared between calls:
    res = exec_query " { r1: resolver1(value: 1) r2: resolver1 }"
    assert_equal [100, 1], res["data"]["r1"]
    assert_equal [100, nil], res["data"]["r2"]
  end

  it "inherits type and arguments" do
    res = exec_query " { r1: resolver2(value: 1, extraValue: 2) r2: resolver2(extraValue: 3) }"
    assert_equal [100, 1, 2], res["data"]["r1"]
    assert_equal [100, nil, 3], res["data"]["r2"]
  end

  it "uses the object's field_class" do
    res = exec_query " { r1: resolver3(value: 1) r2: resolver3 }"
    assert_equal [100, 1, -1], res["data"]["r1"]
    assert_equal [100, nil, -1], res["data"]["r2"]
  end

  describe "resolve method" do
    it "has access to the application object" do
      res = exec_query " { resolver4 } ", root_value: OpenStruct.new(value: 4)
      assert_equal 13, res["data"]["resolver4"]
    end

    it "gets extras" do
      res = exec_query " { resolver4 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 9, res["data"]["resolver4"]
    end

    it "gets path from extras" do
      res = exec_query " { resolverWithPath } ", root_value: OpenStruct.new(value: 0)
      assert_equal '["resolverWithPath"]', res["data"]["resolverWithPath"]
    end
  end

  describe "load_application_object_failed hook" do
    it "isn't called for successful queries" do
      query_str = <<-GRAPHQL
      {
        resolverWithErrorHandler(int: "abcd") { value }
      }
      GRAPHQL

      res = exec_query(query_str)
      assert_equal 16, res["data"]["resolverWithErrorHandler"]["value"]
      refute res.key?("errors")
    end

    describe "when the id doesn't find anything" do
      it "passes an error to the handler" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "failed_to_find") { value }
        }
        GRAPHQL

        res = exec_query(query_str)
        assert_nil res["data"].fetch("resolverWithErrorHandler")
        expected_err = "ResolverWithErrorHandler failed for id: \"failed_to_find\" (nil) (GraphQL::LoadApplicationObjectFailedError)"
        assert_equal [expected_err], res["errors"].map { |e| e["message"] }
      end

      it "uses rescue_from handlers" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "failed_to_find") { value }
        }
        GRAPHQL

        res = exec_query(query_str, context: { reraise_special_error: true })
        assert_nil res["data"].fetch("resolverWithErrorHandler")
        expected_err = "A special error was raised from \"failed_to_find\""
        assert_equal [expected_err], res["errors"].map { |e| e["message"] }
      end

      it "uses the new value from lookup" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "failed_to_find") { value }
        }
        GRAPHQL

        res = exec_query(query_str, context: { fallback_object: 212 })
        assert_equal 848, res["data"]["resolverWithErrorHandler"]["value"]
        refute res.key?("errors")
      end

      it "halts silently when it returns nil" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "failed_to_find") { value }
        }
        GRAPHQL

        res = exec_query(query_str, context: { return_nil_on_load_failed: true })
        assert_nil res["data"].fetch("resolverWithErrorHandler")
        refute res.key?("errors")
      end
    end

    describe "when resolve_type returns a no-good type" do
      it "calls the handler" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "resolve_type_as_wrong_type") { value }
        }
        GRAPHQL

        res = exec_query(query_str)
        assert_nil res["data"].fetch("resolverWithErrorHandler")
        expected_err = "ResolverWithErrorHandler failed for id: \"resolve_type_as_wrong_type\" (:resolve_type_as_wrong_type) (GraphQL::LoadApplicationObjectFailedError)"
        assert_equal [expected_err], res["errors"].map { |e| e["message"] }
      end

      it "uses rescue_from handlers" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "resolve_type_as_wrong_type") { value }
        }
        GRAPHQL

        res = exec_query(query_str, context: { reraise_special_error: true })
        assert_nil res["data"].fetch("resolverWithErrorHandler")
        expected_err = "A special error was raised from \"resolve_type_as_wrong_type\""
        assert_equal [expected_err], res["errors"].map { |e| e["message"] }
      end

      it "uses a new value from resolve_type" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "resolve_type_as_wrong_type") { value }
        }
        GRAPHQL

        res = exec_query(query_str, context: { fallback_object: 4 })
        assert_equal 16, res["data"]["resolverWithErrorHandler"]["value"]
        refute res.key?("errors")
      end

      it "halts silently when it returns nil" do
        query_str = <<-GRAPHQL
        {
          resolverWithErrorHandler(int: "resolve_type_as_wrong_type") { value }
        }
        GRAPHQL

        res = exec_query(query_str, context: { return_nil_on_load_failed: true })
        assert_nil res["data"].fetch("resolverWithErrorHandler")
        refute res.key?("errors")
      end
    end
  end


  describe "extras" do
    it "is inherited" do
      res = exec_query " { resolver4 resolver5 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 9, res["data"]["resolver4"]
      assert_equal 9, res["data"]["resolver5"]
    end
  end

  describe "complexity" do
    it "has default values" do
      res = exec_query " { resolver6 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 1, res["data"]["resolver6"]
    end

    it "is inherited" do
      res = exec_query " { resolver7 resolver8 } ", root_value: OpenStruct.new(value: 0)
      assert_equal 2, res["data"]["resolver7"]
      assert_equal 2, res["data"]["resolver8"]
    end
  end

  describe "description" do
    it "is inherited" do
      expected_desc = "Adds object.value to ast_node.name.size"
      assert_equal expected_desc, ResolverTest::Resolver4.description
      assert_equal expected_desc, ResolverTest::Resolver5.description
    end
  end

  describe "when applied to a field" do
    it "gets the field's description" do
      assert_nil ResolverTest::Schema.find("Query.resolver3").description
      assert_equal "field desc", ResolverTest::Schema.find("Query.resolver3Again").description
      assert_equal "Positional description", ResolverTest::Schema.find("Query.resolver4").description
    end

    it "gets the field's name" do
      # Matching name:
      assert ResolverTest::Schema.find("Query.resolver3")
      # Mismatched name:
      assert ResolverTest::Schema.find("Query.resolver3Again")
    end
  end

  describe "preparing inputs" do
    # Add assertions for a given field, assuming the behavior of `check_for_magic_number`
    def add_error_assertions(field_name, description)
      res = exec_query("{ int: #{field_name}(int: 13) }")
      assert_nil res["data"].fetch("int"), "#{description}: no result for execution error"
      assert_equal ["13 is unlucky!"], res["errors"].map { |e| e["message"] }, "#{description}: top-level error is added"

      res = exec_query("{ int: #{field_name}(int: 200) }")
      assert_nil res["data"].fetch("int"), "#{description}: No result for authorization error"
      refute res.key?("errors"), "#{description}: silent auth failure (no top-level error)"
    end

    it "keeps track of the `loads:` option" do
      arg = ResolverTest::MutationWithNullableLoadsArgument.arguments["labelId"]
      assert_equal ResolverTest::HasValue, arg.loads
    end

    describe "ready?" do
      it "can raise errors" do
        res = exec_query("{ int: prepResolver5(int: 5) }")
        assert_equal 50, res["data"]["int"]
        add_error_assertions("prepResolver5", "ready?")
      end

      it "can raise errors in lazy sync" do
        res = exec_query("{ int: prepResolver6(int: 5) }")
        assert_equal 50, res["data"]["int"]
        add_error_assertions("prepResolver6", "lazy ready?")
      end

      it "can return false and data" do
        res = exec_query("{ int: prepResolver7(int: 13) { errors int } }")
        assert_equal ["Bad number!"], res["data"]["int"]["errors"]

        res = exec_query("{ int: prepResolver7(int: 213) { errors int } }")
        assert_equal 213, res["data"]["int"]["int"]
      end

      it "can return false and falsey data" do
        res = exec_query("{ result: resolverWithFalseyValueReady }")
        assert_equal false, res["data"]["result"] # must be `false`, not just falsey
        assert_nil res["errors"]
      end

      it 'raises the correct error on invalid return type' do
        err = assert_raises(RuntimeError) do
          exec_query("mutation { resolverWithInvalidReady(int: 2) { int } }")
        end
        assert_match("Unexpected result from #ready?", err.message)
      end
    end

    describe "loading arguments" do
      it "calls load methods and injects the return value" do
        res = exec_query("{ prepResolver1(int: 5) }")
        assert_equal 50, res["data"]["prepResolver1"], "The load multiplier was called"
      end

      it "supports lazy values" do
        res = exec_query("{ prepResolver2(int: 5) }")
        assert_equal 15, res["data"]["prepResolver2"], "The load multiplier was called"
      end

      it "supports raising GraphQL::UnauthorizedError and GraphQL::ExecutionError" do
        res = exec_query("{ prepResolver3(int: 5) }")
        assert_equal 5, res["data"]["prepResolver3"]
        add_error_assertions("prepResolver3", "load_ hook")
      end

      it "supports raising errors from promises" do
        res = exec_query("{ prepResolver4(int: 5) }")
        assert_equal 5, res["data"]["prepResolver4"]
        add_error_assertions("prepResolver4", "lazy load_ hook")
      end
    end

    describe "validating arguments" do
      describe ".authorized?" do
        it "can raise an error to halt" do
          res = exec_query("{ prepResolver10(int1: 5, int2: 6) }", context: { max_int: 9 })
          assert_equal ["Inputs too big"], res["errors"].map { |e| e["message"] }

          res = exec_query("{ prepResolver10(int1: 5, int2: 6) }", context: { max_int: 90 })
          assert_equal 11, res["data"]["prepResolver10"]
        end

        it "uses the argument name provided in `as:`" do
          res = exec_query("{ prepResolver10(int1: 5, int2: 6) }", context: { max_int: 90 })
          assert_equal 11, res["data"]["prepResolver10"]
        end

        it "can return a lazy object" do
          # This is too big because it's modified in the overridden authorized? hook:
          res = exec_query("{ prepResolver11(int1: 3, int2: 5) }", context: { max_int: 9 })
          assert_equal ["Inputs too big"], res["errors"].map { |e| e["message"] }

          res = exec_query("{ prepResolver11(int1: 3, int2: 5) }", context: { max_int: 90 })
          assert_equal 8, res["data"]["prepResolver11"]
        end

        it "can return data early" do
          res = exec_query("{ prepResolver12(int1: 9, int2: 5) { errorMessages } }", context: { max_int: 9 })
          assert_equal ["Inputs must be less than 9 (but you provided 14)"], res["data"]["prepResolver12"]["errorMessages"]
          # This works
          res = exec_query("{ prepResolver12(int1: 2, int2: 5) { value } }", context: { max_int: 9 })
          assert_equal 7, res["data"]["prepResolver12"]["value"]
        end

        it "can return falsey data early" do
          res = exec_query("{ result: resolverWithFalseyValueAuthorized }")
          assert_equal false, res["data"]["result"] # must be actual `false`, not just a falsey `nil`
          assert_nil res["errors"]
        end

        it "can return data early in a promise" do
          # This is too big because it's modified in the overridden authorized? hook:
          res = exec_query("{ prepResolver13(int1: 4, int2: 4) { errorMessages } }", context: { max_int: 9 })
          assert_equal ["Inputs must be less than 9 (but you provided 10)"], res["data"]["prepResolver13"]["errorMessages"]
          # This works
          res = exec_query("{ prepResolver13(int1: 2, int2: 5) { value } }", context: { max_int: 9 })
          assert_equal 7, res["data"]["prepResolver13"]["value"]
        end

        it "can return false to halt" do
          str = <<-GRAPHQL
          {
            prepResolver10(int1: 5, int2: 10)
            prepResolver11(int1: 3, int2: 5)
          }
          GRAPHQL
          res = exec_query(str, context: { max_int: 100, min_int: 20 })
          assert_equal({ "prepResolver10" => nil, "prepResolver11" => nil }, res["data"])
        end

        it "works with no arguments for RelayClassicMutation" do
          res = exec_query("{ prepResolver14(input: {}) { number } }")
          assert_equal 1, res["data"]["prepResolver14"]["number"]
        end

        it "uses loaded objects" do
          query_str = "{ prepResolver9(intId: 9) { value } }"
          # This will cause an unauthorized response
          # by `HasValue.authorized?`
          context = { max_value: 8 }
          res = exec_query(query_str, context: context)
          assert_nil res["data"]["prepResolver9"]
          assert_equal ["Unauthorized IntegerWrapper loaded for prepResolver9"], res["errors"].map { |e| e["message"] }

          # This is OK
          context = { max_value: 900 }
          res = exec_query(query_str, context: context)
          assert_equal 51, res["data"]["prepResolver9"]["value"]
          # This is the transformation applied by the resolver,
          # just make sure it matches the response
          assert_equal 51, (9 + "HasValue".size) * 3

          # It uses the returned value from unauthorized object
          context = { max_value: 8, use_replacement: 2 }
          res = exec_query(query_str, context: context)
          assert_equal 6, res["data"]["prepResolver9"]["value"]
          refute res.key?("errors")
        end
      end
    end

    describe "load_* argument methods" do
      it "doesn't override inherited methods" do
        r1 = Class.new(GraphQL::Schema::Resolver) do
          def load_input(input); end
        end
        r2 = Class.new(r1) do
          argument :input, Integer, required: false
        end

        assert_equal r1.instance_method(:load_input).source_location, r2.instance_method(:load_input).source_location
      end
    end

    describe "Loading inputs" do
      it "calls object_from_id" do
        res = exec_query('{ prepResolver9(intId: "5") { value } }')
        # (5 + 8) * 3
        assert_equal 39, res["data"]["prepResolver9"]["value"]
      end

      it "supports loading array of ids" do
        res = exec_query('{ prepResolver9Array(intIds: ["1", "10", "100"]) { value } }')
        # (1 + 8) * 3
        # (10 + 8) * 3
        # (100 + 8) * 3
        assert_equal [27, 54, 324], res["data"]["prepResolver9Array"].map { |v| v["value"] }
      end

      it "preserves `nil` when nullable argument is provided `null`" do
        res = exec_query("mutation { mutationWithNullableLoadsArgument(labelId: null) { inputs } }")

        assert_nil res["errors"]
        assert_equal '{"label":null}', res["data"]["mutationWithNullableLoadsArgument"]["inputs"]
      end

      it "preserves `nil` when nullable list argument is provided `null`" do
        res = exec_query("mutation { mutationWithNullableLoadsArgument(labelIds: null) { inputs } }")

        assert_nil res["errors"]
        assert_equal '{"labels":null}', res["data"]["mutationWithNullableLoadsArgument"]["inputs"]
      end

      it "omits omitted nullable argument" do
        res = exec_query("mutation { mutationWithNullableLoadsArgument { inputs } }")

        assert_nil res["errors"]
        assert_equal "{}", res["data"]["mutationWithNullableLoadsArgument"]["inputs"]
      end

      it "returns an error when nullable argument is provided an invalid value" do
        res = exec_query('mutation { mutationWithNullableLoadsArgument(labelId: "invalid") { inputs } }')

        assert res["errors"]
        assert_equal 'No object found for `labelId: "invalid"`', res["errors"][0]["message"]
      end

      it "returns an error when a non-nullable argument is provided an invalid value" do
        res = exec_query('mutation { mutationWithRequiredLoadsArgument(labelId: "invalid") { inputs } }')

        assert res["errors"]
        assert_equal 'No object found for `labelId: "invalid"`', res["errors"][0]["message"]
      end
    end

    describe "extensions" do
      it "returns extension when no arguments passed" do
        assert 1, ResolverTest::ResolverWithExtension.extensions.count
      end

      it "configures extensions for field" do
        assert_kind_of ResolverTest::GreetingExtension,
                       ResolverTest::Query.fields["resolverWithExtension"].extensions.first
      end

      it "uses extension to build response" do
        res = exec_query " { resolverWithExtension } "
        assert_equal "Hi, Robert!", res["data"]["resolverWithExtension"]
      end

      it "inherits extensions" do
        r1 = Class.new(GraphQL::Schema::Resolver) do
          extension(ResolverTest::GreetingExtension)
        end

        e2 = Class.new(GraphQL::Schema::FieldExtension)
        r2 = Class.new(r1) do
          extension(e2)
        end

        assert_equal 1, r1.extensions.size
        assert_equal 2, r2.extensions.size
      end
    end

    describe "max_page_size" do
      class NoMaxPageSizeResolver < GraphQL::Schema::Resolver
      end

      class MaxPageSizeBaseResolver < GraphQL::Schema::Resolver
        max_page_size 10
      end

      class MaxPageSizeSubclass < MaxPageSizeBaseResolver
      end

      class MaxPageSizeOverrideSubclass < MaxPageSizeBaseResolver
        max_page_size nil
      end

      class ObjectWithMaxPageSizeResolver < GraphQL::Schema::Object
        field :items, [String], null: false, resolver: MaxPageSizeBaseResolver
      end

      it "defaults to absent" do
        assert_nil NoMaxPageSizeResolver.max_page_size
        refute NoMaxPageSizeResolver.has_max_page_size?
      end

      it "implements has_max_page_size?" do
        assert MaxPageSizeBaseResolver.has_max_page_size?
        assert MaxPageSizeSubclass.has_max_page_size?
        assert MaxPageSizeOverrideSubclass.has_max_page_size?
      end

      it "is inherited" do
        assert_equal 10, MaxPageSizeBaseResolver.max_page_size
        assert_equal 10, MaxPageSizeSubclass.max_page_size
      end

      it "is overridden by nil" do
        assert_nil MaxPageSizeOverrideSubclass.max_page_size
      end

      it "is passed along to the field" do
        assert_equal 10, ObjectWithMaxPageSizeResolver.fields["items"].max_page_size
      end
    end

    describe "default_page_size" do
      class NoDefaultPageSizeResolver < GraphQL::Schema::Resolver
      end

      class DefaultPageSizeBaseResolver < GraphQL::Schema::Resolver
        default_page_size 10
      end

      class DefaultPageSizeSubclass < DefaultPageSizeBaseResolver
      end

      class DefaultPageSizeOverrideSubclass < DefaultPageSizeBaseResolver
        default_page_size nil
      end

      class ObjectWithDefaultPageSizeResolver < GraphQL::Schema::Object
        field :items, [String], null: false, resolver: DefaultPageSizeBaseResolver
      end

      it "defaults to absent" do
        assert_nil NoDefaultPageSizeResolver.default_page_size
        refute NoDefaultPageSizeResolver.has_default_page_size?
      end

      it "implements has_default_page_size?" do
        assert DefaultPageSizeBaseResolver.has_default_page_size?
        assert DefaultPageSizeSubclass.has_default_page_size?
        assert DefaultPageSizeOverrideSubclass.has_default_page_size?
      end

      it "is inherited" do
        assert_equal 10, DefaultPageSizeBaseResolver.default_page_size
        assert_equal 10, DefaultPageSizeSubclass.default_page_size
      end

      it "is overridden by nil" do
        assert_nil DefaultPageSizeOverrideSubclass.default_page_size
      end

      it "is passed along to the field" do
        assert_equal 10, ObjectWithDefaultPageSizeResolver.fields["items"].default_page_size
      end
    end
  end

  describe "When the type is forgotten" do
    class ResolverWithoutTypeSchema < GraphQL::Schema
      class WithoutType < GraphQL::Schema::Resolver
        def resolve
          "OK"
        end
      end

      class Query < GraphQL::Schema::Object
      end
    end

    it "raises a nice error" do
      err = assert_raises GraphQL::Schema::Field::MissingReturnTypeError do
        ResolverWithoutTypeSchema::Query.field(:without_type, resolver: ResolverWithoutTypeSchema::WithoutType)
      end
      expected_message = "Can't determine the return type for Query.withoutType (it has `resolver: ResolverWithoutTypeSchema::WithoutType`, perhaps that class is missing a `type ...` declaration, or perhaps its type causes a cyclical loading issue)"
      assert_equal expected_message, err.message
    end
  end

  describe "when the field has configurations that override the resolvers" do
    it "uses the field's type and description, not the resolver's" do
      resolver = Class.new(GraphQL::Schema::Resolver) do
        description "Does things!"
        type(String, null: true)
      end

      field = GraphQL::Schema::Field.new(name: "blah", resolver_class: resolver, description: nil, type: Integer, null: false)
      assert_equal "Int!", field.type.to_type_signature
      assert_equal "String", resolver.type.to_type_signature

      assert_nil field.description
      assert_equal "Does things!", resolver.description
    end
  end


  describe "when authorized? returns false for an argument" do
    class UnauthorizedArgResolverSchema < GraphQL::Schema
      class Echo < GraphQL::Schema::Resolver
        argument :input, String do
          def authorized?(obj, input, ctx)
            if input == "unauthorized"
              false
            else
              true
            end
          end
        end

        type String, null: true

        def resolve(input:)
          input
        end
      end

      class Query < GraphQL::Schema::Object
        field :echo, resolver: Echo
      end

      query(Query)

      def self.unauthorized_field(*)
        raise GraphQL::ExecutionError, "Unauthorized Field"
      end
    end

    it "calls unauthorized_field" do
      assert_equal "ok", UnauthorizedArgResolverSchema.execute("{ echo(input: \"ok\") }")["data"]["echo"]
      unauthorized_res = UnauthorizedArgResolverSchema.execute("{ echo(input: \"unauthorized\") }")
      assert_equal ["Unauthorized Field"], unauthorized_res["errors"].map { |err|  err["message"] }
    end
  end

  describe "with directives" do
    class ResolverDirectivesSchema < GraphQL::Schema

      class GetThing < GraphQL::Schema::Resolver
        directive GraphQL::Schema::Directive::Flagged, by: "getThing"
        argument :id, ID
        type String, null: false
      end

      class GetThingWithoutDirective < GraphQL::Schema::Resolver
        argument :id, ID
        type String, null: false
      end

      class Query < GraphQL::Schema::Object
        field :get_thing, resolver: GetThing
        field :get_thing_flagged, resolver: GetThing, directives: { GraphQL::Schema::Directive::Flagged => { by: "getThingFlagged" } }
        field :get_thing_field, resolver: GetThingWithoutDirective, directives: { GraphQL::Schema::Directive::Flagged => { by: "getField" } }
      end

      query(Query)
    end
  end

  it "caries them into the field definition" do
    expected_str = <<~GRAPHQL
    """
    Hides this part of the schema unless the named flag is present in context[:flags]
    """
    directive @flagged(
      """
      Flags to check for this schema member
      """
      by: [String!]!
    ) on ARGUMENT_DEFINITION | ENUM | ENUM_VALUE | FIELD_DEFINITION | INPUT_FIELD_DEFINITION | INPUT_OBJECT | INTERFACE | OBJECT | SCALAR | UNION

    type Query {
      getThing(id: ID!): String! @flagged(by: ["getThing"])
      getThingField(id: ID!): String! @flagged(by: ["getField"])
      getThingFlagged(id: ID!): String! @flagged(by: ["getThingFlagged"]) @flagged(by: ["getThing"])
    }
    GRAPHQL

    assert_equal expected_str, ResolverDirectivesSchema.to_definition(context: { flags: ["getField", "getThing", "getThingFlagged"] })
  end
end
