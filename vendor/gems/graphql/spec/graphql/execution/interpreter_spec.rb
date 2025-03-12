# frozen_string_literal: true
require "spec_helper"
require_relative "../subscriptions_spec"

describe GraphQL::Execution::Interpreter do
  module InterpreterTest
    class Box
      def initialize(value: nil, &block)
        @value = value
        @block = block
      end

      def value
        if @block
          @value = @block.call
          @block = nil
        end
        @value
      end
    end

    class Expansion < GraphQL::Schema::Object
      field :sym, String, null: false
      field :lazy_sym, String, null: false
      field :name, String, null: false
      field :cards, ["InterpreterTest::Card"], null: false

      def self.authorized?(expansion, ctx)
        if expansion.sym == "NOPE"
          false
        else
          true
        end
      end

      def cards
        Query::CARDS.select { |c| c.expansion_sym == @object.sym }
      end

      def lazy_sym
        Box.new(value: object.sym)
      end

      field :null_union_field_test, Integer, null: false
      def null_union_field_test
        1
      end

      field :always_cached_value, Integer, null: false
      def always_cached_value
        raise "should never be called"
      end
    end

    class Card < GraphQL::Schema::Object
      field :name, String, null: false
      field :colors, "[InterpreterTest::Color]", null: false
      field :expansion, Expansion, null: false

      def expansion
        Query::EXPANSIONS.find { |e| e.sym == @object.expansion_sym }
      end

      field :null_union_field_test, Integer
      def null_union_field_test
        nil
      end

      field :parent_class_name, String, null: false, extras: [:parent]

      def parent_class_name(parent:)
        parent.class.name
      end
    end

    class Color < GraphQL::Schema::Enum
      value "WHITE"
      value "BLUE"
      value "BLACK"
      value "RED"
      value "GREEN"
    end

    class Entity < GraphQL::Schema::Union
      possible_types Card, Expansion

      def self.resolve_type(obj, ctx)
        obj.sym ? Expansion : Card
      end
    end

    class FieldCounter < GraphQL::Schema::Object
      implements GraphQL::Types::Relay::Node

      field :field_counter, FieldCounter, null: false
      def field_counter; self.class.generate_tag(context); end

      field :calls, Integer, null: false do
        argument :expected, Integer
      end

      def calls(expected:)
        c = context[:calls] += 1
        if c != expected
          raise "Expected #{expected} calls but had #{c} so far"
        else
          c
        end
      end

      field :runtime_info, String, null: false do
        argument :a, Integer, required: false
        argument :b, Integer, required: false
      end

      def runtime_info(a: nil, b: nil)
        inspect_context
      end

      field :lazy_runtime_info, String, null: false do
        argument :a, Integer, required: false
        argument :b, Integer, required: false
      end

      def lazy_runtime_info(a: nil, b: nil)
        Box.new { inspect_context }
      end

      def self.generate_tag(context)
        context[:field_counters_count] ||= 0
        current_count = context[:field_counters_count] += 1
        "field_counter_#{current_count}"
      end

      private

      def inspect_context
        "<#{interpreter_context_for(:current_object).object.inspect}> #{interpreter_context_for(:current_path)} -> #{interpreter_context_for(:current_field).path}(#{interpreter_context_for(:current_arguments).size})"
      end

      def interpreter_context_for(key)
        # Make sure it's set in query context and interpreter namespace.
        base_ctx_value = context[key]
        interpreter_ctx_value = context.namespace(:interpreter)[key]
        if base_ctx_value != interpreter_ctx_value
          raise "Context mismatch for #{key} -> #{base_ctx_value} / interpreter: #{interpreter_ctx_value}"
        else
          base_ctx_value
        end
      end
    end

    class Query < GraphQL::Schema::Object
      # Try a root-level authorized hook that returns a lazy value
      def self.authorized?(obj, ctx)
        Box.new(value: true)
      end

      field :card, Card do
        argument :name, String
      end

      def card(name:)
        Box.new(value: CARDS.find { |c| c.name == name })
      end

      field :expansion, Expansion do
        argument :sym, String
      end

      def expansion(sym:)
        EXPANSIONS.find { |e| e.sym == sym }
      end

      field :expansion_raw, Expansion, null: false

      def expansion_raw
        raw_value(sym: "RAW", name: "Raw expansion", always_cached_value: 42)
      end

      field :expansion_mixed, [Expansion], null: false

      def expansion_mixed
        expansions + [expansion_raw]
      end

      field :expansions, [Expansion], null: false
      def expansions
        EXPANSIONS
      end

      class ExpansionData < OpenStruct
      end

      CARDS = [
        OpenStruct.new(name: "Dark Confidant", colors: ["BLACK"], expansion_sym: "RAV"),
      ]

      EXPANSIONS = [
        ExpansionData.new(name: "Ravnica, City of Guilds", sym: "RAV"),
        # This data has an error, for testing null propagation
        ExpansionData.new(name: nil, sym: "XYZ"),
        # This is not allowed by .authorized?,
        ExpansionData.new(name: nil, sym: "NOPE"),
      ]

      field :find, [Entity], null: false do
        argument :id, [ID]
      end

      def find(id:)
        id.map do |ent_id|
          Query::EXPANSIONS.find { |e| e.sym == ent_id } ||
            Query::CARDS.find { |c| c.name == ent_id }
        end
      end

      field :find_many, [Entity, null: true], null: false do
        argument :ids, [ID]
      end

      def find_many(ids:)
        find(id: ids).map { |e| Box.new(value: e) }
      end

      field :field_counter, FieldCounter, null: false
      def field_counter; FieldCounter.generate_tag(context) ; end

      include GraphQL::Types::Relay::HasNodeField
      include GraphQL::Types::Relay::HasNodesField

      class NestedQueryResult < GraphQL::Schema::Object
        field :result, String
        field :current_path, [String]
      end

      field :nested_query, NestedQueryResult do
        argument :query, String
      end

      def nested_query(query:)
        result = context.schema.multiplex([{query: query}], context: { allow_pending_thread_state: true }).first
        {
          result: JSON.dump(result),
          current_path: context[:current_path],
        }
      end
    end

    class Counter < GraphQL::Schema::Object
      field :value, Integer, null: false
      field :lazy_value, Integer, null: false

      def lazy_value
        Box.new { object.value }
      end

      field :increment, Counter, null: false

      def increment
        object.value += 1
        object
      end
    end

    class Mutation < GraphQL::Schema::Object
      field :increment_counter, Counter, null: false

      def increment_counter
        counter = context[:counter]
        counter.value += 1
        counter
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      mutation(Mutation)
      lazy_resolve(Box, :value)

      use GraphQL::Schema::AlwaysVisible

      def self.object_from_id(id, ctx)
        OpenStruct.new(id: id)
      end

      def self.id_from_object(obj, type, ctx)
        obj.id
      end

      def self.resolve_type(type, obj, ctx)
        FieldCounter
      end

      class EnsureArgsAreObject
        def self.trace(event, data)
          case event
          when "execute_field", "execute_field_lazy"
            args = data[:query].context[:current_arguments]
            if !args.is_a?(GraphQL::Execution::Interpreter::Arguments)
              raise "Expected arguments object, got #{args.class}: #{args.inspect}"
            end
          end
          yield
        end
      end
      tracer EnsureArgsAreObject

      module EnsureThreadCleanedUp
        def execute_multiplex(multiplex:)
          res = super
          runtime_info = Fiber[:__graphql_runtime_info]
          if !runtime_info.nil? && runtime_info != {}
            if !multiplex.context[:allow_pending_thread_state]
              # `nestedQuery` can allow this
              raise "Query did not clean up runtime state, found: #{runtime_info.inspect}"
            end
          end
          res
        end
      end
      trace_with(EnsureThreadCleanedUp)
    end
  end

  it "runs a query" do
    query_string = <<-GRAPHQL
    query($expansion: String!, $id1: ID!, $id2: ID!){
      card(name: "Dark Confidant") {
        colors
        expansion {
          ... {
            name
          }
          cards {
            name
          }
        }
      }
      expansion(sym: $expansion) {
        ... ExpansionFields
      }
      find(id: [$id1, $id2]) {
        __typename
        ... on Card {
          name
        }
        ... on Expansion {
          sym
        }
      }
    }

    fragment ExpansionFields on Expansion {
      cards {
        name
      }
    }
    GRAPHQL

    vars = {expansion: "RAV", id1: "Dark Confidant", id2: "RAV"}
    result = InterpreterTest::Schema.execute(query_string, variables: vars)
    assert_equal ["BLACK"], result["data"]["card"]["colors"]
    assert_equal "Ravnica, City of Guilds", result["data"]["card"]["expansion"]["name"]
    assert_equal [{"name" => "Dark Confidant"}], result["data"]["card"]["expansion"]["cards"]
    assert_equal [{"name" => "Dark Confidant"}], result["data"]["expansion"]["cards"]
    expected_abstract_list = [
      {"__typename" => "Card", "name" => "Dark Confidant"},
      {"__typename" => "Expansion", "sym" => "RAV"},
    ]
    assert_equal expected_abstract_list, result["data"]["find"]
    assert_nil Fiber[:__graphql_runtime_info]
  end

  it "runs a nested query and maintains proper state" do
    query_str = "query($queryStr: String!) { nestedQuery(query: $queryStr) { result currentPath } }"
    result = InterpreterTest::Schema.execute(query_str, variables: { queryStr: "{ __typename }" })
    assert_equal '{"data":{"__typename":"Query"}}', result["data"]["nestedQuery"]["result"]
    assert_equal ["nestedQuery"], result["data"]["nestedQuery"]["currentPath"]
    assert_nil Fiber[:__graphql_runtime_info]
  end

  it "runs mutation roots atomically and sequentially" do
    query_str = <<-GRAPHQL
    mutation {
      i1: incrementCounter { value lazyValue
        i2: increment { value lazyValue }
        i3: increment { value lazyValue }
      }
      i4: incrementCounter { value lazyValue }
      i5: incrementCounter { value lazyValue }
    }
    GRAPHQL

    result = InterpreterTest::Schema.execute(query_str, context: { counter: OpenStruct.new(value: 0) })
    expected_data = {
      "i1" => {
        "value" => 1,
        # All of these get `3` as lazy value. They're resolved together,
        # since they aren't _root_ mutation fields.
        "lazyValue" => 3,
        "i2" => { "value" => 2, "lazyValue" => 3 },
        "i3" => { "value" => 3, "lazyValue" => 3 },
      },
      "i4" => { "value" => 4, "lazyValue" => 4},
      "i5" => { "value" => 5, "lazyValue" => 5},
    }
    assert_equal expected_data, result["data"]
  end

  it "runs skip and include" do
    query_str = <<-GRAPHQL
    query($truthy: Boolean!, $falsey: Boolean!){
      exp1: expansion(sym: "RAV") @skip(if: true) { name }
      exp2: expansion(sym: "RAV") @skip(if: false) { name }
      exp3: expansion(sym: "RAV") @include(if: true) { name }
      exp4: expansion(sym: "RAV") @include(if: false) { name }
      exp5: expansion(sym: "RAV") @include(if: $truthy) { name }
      exp6: expansion(sym: "RAV") @include(if: $falsey) { name }
    }
    GRAPHQL

    vars = {truthy: true, falsey: false}
    result = InterpreterTest::Schema.execute(query_str, variables: vars)
    expected_data = {
      "exp2" => {"name" => "Ravnica, City of Guilds"},
      "exp3" => {"name" => "Ravnica, City of Guilds"},
      "exp5" => {"name" => "Ravnica, City of Guilds"},
    }
    assert_equal expected_data, result["data"]
    assert_nil Fiber[:__graphql_runtime_info]
  end

  describe "runtime info in context" do
    it "is available" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        fieldCounter {
          runtimeInfo(a: 1, b: 2)
          fieldCounter {
            runtimeInfo
            lazyRuntimeInfo(a: 1)
          }
        }
      }
      GRAPHQL

      assert_equal '<"field_counter_1"> ["fieldCounter", "runtimeInfo"] -> FieldCounter.runtimeInfo(2)', res["data"]["fieldCounter"]["runtimeInfo"]
      # These are both `field_counter_2`, but one is lazy
      assert_equal '<"field_counter_2"> ["fieldCounter", "fieldCounter", "runtimeInfo"] -> FieldCounter.runtimeInfo(0)', res["data"]["fieldCounter"]["fieldCounter"]["runtimeInfo"]
      assert_equal '<"field_counter_2"> ["fieldCounter", "fieldCounter", "lazyRuntimeInfo"] -> FieldCounter.lazyRuntimeInfo(1)', res["data"]["fieldCounter"]["fieldCounter"]["lazyRuntimeInfo"]
    end
  end

  describe "null propagation" do
    it "propagates nulls" do
      query_str = <<-GRAPHQL
      {
        expansion(sym: "XYZ") {
          name
          sym
          lazySym
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      # Although the expansion was found, its name of `nil`
      # propagated to here
      assert_nil res["data"].fetch("expansion")
      assert_equal ["Cannot return null for non-nullable field Expansion.name"], res["errors"].map { |e| e["message"] }
      assert_nil Fiber[:__graphql_runtime_info]
    end

    it "places errors ahead of data in the response" do
      query_str = <<-GRAPHQL
      {
        expansion(sym: "XYZ") {
          name
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      assert_equal ["errors", "data"], res.keys
    end

    it "propagates nulls in lists" do
      query_str = <<-GRAPHQL
      {
        expansions {
          name
          sym
          lazySym
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      # A null in one of the list items removed the whole list
      assert_nil(res["data"])
    end

    it "works with unions that fail .authorized?" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        find(id: "NOPE") {
          ... on Expansion {
            sym
          }
        }
      }
      GRAPHQL
      assert_equal ["Cannot return null for non-nullable field Query.find"], res["errors"].map { |e| e["message"] }
    end

    it "works with lists of unions" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        findMany(ids: ["RAV", "NOPE", "BOGUS"]) {
          ... on Expansion {
            sym
          }
        }
      }
      GRAPHQL

      assert_equal 3, res["data"]["findMany"].size
      assert_equal "RAV", res["data"]["findMany"][0]["sym"]
      assert_nil res["data"]["findMany"][1]
      assert_nil res["data"]["findMany"][2]
      assert_equal false, res.key?("errors")

      assert_equal Hash, res["data"].class
      assert_equal Array, res["data"]["findMany"].class
    end

    it "works with union lists that have members of different kinds, with different nullabilities" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        findMany(ids: ["RAV", "Dark Confidant"]) {
          ... on Expansion {
            nullUnionFieldTest
          }
          ... on Card {
            nullUnionFieldTest
          }
        }
      }
      GRAPHQL

      assert_equal [1, nil], res["data"]["findMany"].map { |f| f["nullUnionFieldTest"] }
    end
  end

  describe "duplicated fields" do
    it "doesn't run them multiple times" do
      query_str = <<-GRAPHQL
      {
        fieldCounter {
          calls(expected: 1)
          # This should not be called since it matches the above
          calls(expected: 1)
          fieldCounter {
            calls(expected: 2)
          }
          ...ExtraFields
        }
      }
      fragment ExtraFields on FieldCounter {
        fieldCounter {
          # This should not be called since it matches the inline field:
          calls(expected: 2)
          # This _should_ be called
          c3: calls(expected: 3)
        }
      }
      GRAPHQL

      # It will raise an error if it doesn't match the expectation
      res = InterpreterTest::Schema.execute(query_str, context: { calls: 0 })
      assert_equal 3, res["data"]["fieldCounter"]["fieldCounter"]["c3"]
    end
  end

  describe "backwards compatibility" do
    it "handles a legacy nodes field" do
      res = InterpreterTest::Schema.execute('{ node(id: "abc") { id } }')
      assert_equal "abc", res["data"]["node"]["id"]

      res = InterpreterTest::Schema.execute('{ nodes(ids: ["abc", "xyz"]) { id } }')
      assert_equal ["abc", "xyz"], res["data"]["nodes"].map { |n| n["id"] }
    end
  end

  describe "returning raw values" do
    it "returns raw value" do
      query_str = <<-GRAPHQL
      {
        expansionRaw {
          name
          sym
          alwaysCachedValue
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      assert_equal({ sym: "RAW", name: "Raw expansion", always_cached_value: 42 }, res["data"]["expansionRaw"])
    end
  end

  describe "returning raw values and resolved fields" do
    it "returns raw value" do
      query_str = <<-GRAPHQL
      {
        expansionRaw {
          name
          sym
          alwaysCachedValue
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      assert_equal({ sym: "RAW", name: "Raw expansion", always_cached_value: 42 }, res["data"]["expansionRaw"])
    end
  end

  describe "Lazy skips" do
    class LazySkipSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        def self.authorized?(obj, ctx)
          -> { true }
        end
        field :skip, String

        def skip
          context.skip
        end

        field :lazy_skip, String
        def lazy_skip
          -> { context.skip }
        end

        field :mixed_skips, [String]
        def mixed_skips
          [
            "a",
            context.skip,
            "c",
            -> { context.skip },
            "e",
          ]
        end
      end

      class NothingSubscription < GraphQL::Schema::Subscription
        field :nothing, String
        def authorized?(*)
          -> { true }
        end

        def update
          { nothing: object }
        end
      end

      class Subscription < GraphQL::Schema::Object
        field :nothing, subscription: NothingSubscription
      end

      query Query
      subscription Subscription
      use InMemoryBackend::Subscriptions, extra: nil
      lazy_resolve Proc, :call
    end

    it "skips properly" do
      res = LazySkipSchema.execute("{ skip }")
      assert_equal({}, res["data"])
      refute res.key?("errors")

      res = LazySkipSchema.execute("{ mixedSkips }")
      assert_equal({ "mixedSkips" => ["a", "c", "e"] }, res["data"])
      refute res.key?("errors")

      res = LazySkipSchema.execute("{ lazySkip }")
      assert_equal({}, res["data"])
      refute res.key?("errors")

      res = LazySkipSchema.execute("subscription { nothing { nothing } }")
      assert_equal({}, res["data"])
      refute res.key?("errors")
      # Make sure an update works properly
      LazySkipSchema.subscriptions.trigger(:nothing, {}, :nothing_at_all)
      _key, updates = LazySkipSchema.subscriptions.deliveries.first
      assert_equal "nothing_at_all", updates[0]["data"]["nothing"]["nothing"]
    end
  end

  describe "GraphQL::ExecutionErrors from connection fields" do
    module ConnectionErrorTest
      class BaseField < GraphQL::Schema::Field
        def authorized?(obj, args, ctx)
          ctx[:authorized_calls] ||= 0
          ctx[:authorized_calls] += 1
          raise GraphQL::ExecutionError, "#{name} is not authorized"
        end
      end

      class BaseConnection < GraphQL::Types::Relay::BaseConnection
        node_nullable(false)
        edge_nullable(false)
        edges_nullable(false)
      end

      class BaseEdge < GraphQL::Types::Relay::BaseEdge
        node_nullable(false)
      end

      class Thing < GraphQL::Schema::Object
        field_class BaseField
        connection_type_class BaseConnection
        edge_type_class BaseEdge
        field :title, String, null: false
        field :body, String, null: false
      end

      class Query < GraphQL::Schema::Object
        field :things, Thing.connection_type, null: false

        def things
          [{title: "a"}, {title: "b"}, {title: "c"}]
        end

        field :thing, Thing, null: false

        def thing
          {
            title: "a",
            body: "b",
          }
        end
      end

      class Schema < GraphQL::Schema
        query Query
      end
    end

    it "returns only 1 error and stops resolving fields after that" do
      res = ConnectionErrorTest::Schema.execute("{ things { nodes { title } } }")
      assert_equal 1, res["errors"].size
      assert_equal 1, res.context[:authorized_calls]

      res = ConnectionErrorTest::Schema.execute("{ things { edges { node { title } } } }")
      assert_equal 1, res["errors"].size
      assert_equal 1, res.context[:authorized_calls]

      res = ConnectionErrorTest::Schema.execute("{ thing { title body } }")
      assert_equal 1, res["errors"].size
      assert_equal 1, res.context[:authorized_calls]
    end
  end

  describe "GraphQL::ExecutionErrors from non-null list fields" do
    module ListErrorTest
      class BaseField < GraphQL::Schema::Field
        def authorized?(*)
          raise GraphQL::ExecutionError, "#{name} is not authorized"
        end
      end

      class Thing < GraphQL::Schema::Object
        field_class BaseField
        field :title, String, null: false
      end

      class Query < GraphQL::Schema::Object
        field :things, [Thing], null: false

        def things
          [{title: "a"}, {title: "b"}, {title: "c"}]
        end
      end

      class Schema < GraphQL::Schema
        query Query
      end
    end

    it "returns only 1 error" do
      res = ListErrorTest::Schema.execute("{ things { title } }")
      assert_equal 1, res["errors"].size
    end
  end

  describe "Invalid null from raised execution error doesn't halt parent fields" do
    class RaisedErrorSchema < GraphQL::Schema
      module Iface
        include GraphQL::Schema::Interface

        field :bar, String, null: false
      end

      class Txn < GraphQL::Schema::Object
        field :fails, String, null: false

        def fails
          raise GraphQL::ExecutionError, "boom"
        end
      end

      class Concrete < GraphQL::Schema::Object
        implements Iface

        field :txn, Txn

        def txn
          {}
        end

        field :msg, String

        def msg
          "THIS SHOULD SHOW UP"
        end
      end

      class Query < GraphQL::Schema::Object
        field :iface, Iface

        def iface
          {}
        end
      end

      query(Query)
      orphan_types([Concrete])

      def self.resolve_type(type, obj, ctx)
        Concrete
      end
    end

    it "resolves fields on the parent object" do
      querystring = """
      {
        iface {
          ... on Concrete {
            txn {
              fails
            }
            msg
          }
        }
      }
      """

      result = RaisedErrorSchema.execute(querystring)
      expected_result = {
        "data" => {
          "iface" => { "txn" => nil, "msg" => "THIS SHOULD SHOW UP" },
        },
        "errors" => [
          {
            "message"=>"boom",
            "locations"=>[{"line"=>6, "column"=>15}],
            "path"=>["iface", "txn", "fails"]
          },
        ],
      }
      assert_equal expected_result, result.to_h
    end
  end

  it "supports extras: [:parent]" do
    query_str = <<-GRAPHQL
    {
      card(name: "Dark Confidant") {
        parentClassName
      }
      expansion(sym: "RAV") {
        cards {
          parentClassName
        }
      }
    }
    GRAPHQL
    res = InterpreterTest::Schema.execute(query_str, context: { calls: 0 })

    assert_equal "NilClass", res["data"]["card"].fetch("parentClassName")
    assert_equal "InterpreterTest::Query::ExpansionData", res["data"]["expansion"]["cards"].first["parentClassName"]
  end

  describe "fragment used twice in different ways" do
    class FragmentBugSchema < GraphQL::Schema
      class ProductVariant < GraphQL::Schema::Object
        field :product, "FragmentBugSchema::Product"
      end

      class Product < GraphQL::Schema::Object
        field :id, ID
        field :variants, [ProductVariant]

        def variants
          [{ product: { id: "1" } }]
        end
      end

      class Query < GraphQL::Schema::Object
        field :variant, ProductVariant

        def variant
          { product: { id: "1" } }
        end
      end

      query(Query)
    end

    it "executes successfully" do
      query_str = <<-GRAPHQL
      {
        variant {
          ...variantFields
          ... on ProductVariant {
            product {
              variants {
                ...variantFields
              }
            }
          }
        }
      }

      fragment variantFields on ProductVariant {
        product {
          id
        }
      }
      GRAPHQL

      res = FragmentBugSchema.execute(query_str).to_h

      expected_result = { "variant" => { "product" => { "id" => "1", "variants" => [ { "product" => { "id" => "1" } } ] } } }
      assert_equal(expected_result, res["data"])
    end
  end
end
