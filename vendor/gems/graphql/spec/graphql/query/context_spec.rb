# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Context do
  after do
    # Clean up test fixtures so they don't pollute later tests
    # (Usually this is cleaned up by execution code, but many tests here don't actually execute queries)
    Fiber[:__graphql_runtime_info] = nil
  end

  class ContextTestSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :context, String, resolver_method: :fetch_context_key do
        argument :key, String
      end

      def fetch_context_key(key:)
        context[key]
      end

      field :query_name, String

      def query_name
        context.query.class.name
      end

      field :push_query_error, Integer, null: false

      def push_query_error
        context.add_error(GraphQL::ExecutionError.new("Query-level error"))
        1
      end
    end

    query(Query)
  end

  let(:schema) { ContextTestSchema }
  let(:result) { schema.execute(query_string, root_value: "rootval", context: {"some_key" => "some value"})}

  describe "access to passed-in values" do
    let(:query_string) { %|
      query getCtx { context(key: "some_key") }
    |}

    it "passes context to fields" do
      expected = {"data" => {"context" => "some value"}}
      assert_equal(expected, result)
    end
  end

  describe "access to the query" do
    let(:query_string) { %|
      query getCtx { queryName }
    |}

    it "provides access to the query object" do
      expected = {"data" => {"queryName" => "GraphQL::Query"}}
      assert_equal(expected, result)
    end
  end

  describe "empty values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

    it "returns returns nil and reports key? => false" do
      assert_nil(context[:some_key])
      assert_equal(false, context.key?(:some_key))
      assert_raises(KeyError) { context.fetch(:some_key) }
    end
  end

  describe "assigning values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

    it "allows you to assign new contexts" do
      assert_nil(context[:some_key])
      context[:some_key] = "wow!"
      assert_equal("wow!", context[:some_key])
    end

    describe "namespaces" do
      let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: 1}) }

      it "doesn't conflict with base values" do
        ns = context.namespace(:stuff)
        ns[:b] = 2
        assert_equal({a: 1}, context.to_h)
        assert_equal({b: 2}, context.namespace(:stuff))
      end
    end
  end

  describe "read values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: {b: 1}}) }

    it "allows you to read values of contexts using []" do
      assert_equal({b: 1}, context[:a])
    end

    it "allows you to read values of contexts using dig" do
      assert_equal(1, context.dig(:a, :b))
      Fiber[:__graphql_runtime_info] = { context.query => OpenStruct.new(current_arguments: {c: 1}) }
      assert_equal 1, context.dig(:current_arguments, :c)
      assert_equal({c: 1}, context.dig(:current_arguments))
    end
  end

  describe "splatting" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: {b: 1}}) }

    let(:splat) { ->(**context) { context } }

    it "runs successfully" do
      assert_equal({a: { b: 1 }}, splat.call(**context))
    end
  end

  it "can override values set by runtime" do
    context = GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: {a: {b: 1}})
    Fiber[:__graphql_runtime_info] = { context.query => OpenStruct.new({ current_object: :runtime_value }) }
    assert_equal :runtime_value, context[:current_object]
    context[:current_object] = :override_value
    assert_equal :override_value, context[:current_object]
  end

  describe "query-level errors" do
    let(:query_string) { %|
      { pushQueryError }
    |}

    it "allows query-level errors" do
      expected_err = { "message" => "Query-level error" }
      assert_equal [expected_err], result["errors"]
    end
  end

  describe "custom context class" do
    it "can be specified" do
      query_str = '{
        inspectContext
        find(id: "Musician/Herbie Hancock") {
          ... on Musician {
            inspectContext
          }
        }
      }'
      res = Jazz::Schema.execute(query_str, context: { magic_key: :ignored, normal_key: "normal_value" })
      expected_values = ["custom_method", "magic_value", "normal_value"]
      expected_values_with_nil = expected_values + [nil]
      assert_equal expected_values, res["data"]["inspectContext"]
      assert_equal expected_values_with_nil, res["data"]["find"]["inspectContext"]
    end
  end

  describe "scoped context" do
    class LazyBlock
      def initialize(&block)
        @get_value = block
      end

      def value
        @get_value.call
      end
    end

    class PassthroughSource < GraphQL::Dataloader::Source
      def fetch(keys)
        keys
      end
    end

    class IntArraySource < GraphQL::Dataloader::Source
      def fetch(keys)
        keys.map { |k| k.times.map { |i| i } }
      end
    end

    class ContextQuery < GraphQL::Schema::Object
      field :get_scoped_context, String do
        argument :key, String
        argument :lazy, Boolean, required: false, default_value: false
      end

      def get_scoped_context(key:, lazy:)
        result = LazyBlock.new {
          context[key]
        }
        return result if lazy
        result.value
      end

      field :set_scoped_context, ContextQuery, null: false do
        argument :key, String
        argument :value, String
        argument :lazy, Boolean, required: false, default_value: false
      end

      def set_scoped_context(key:, value:, lazy:)
        if lazy
          LazyBlock.new {
            context.scoped_merge!(key => value)
            LazyBlock.new {
              self
            }
          }
        else
          context.scoped_merge!(key => value)
          context.dataloader.with(PassthroughSource).load(self)
        end
      end

      field :int_list, [ContextQuery], null: false

      def int_list
        context.scoped_set!("int_list", "assigned")
        context.dataloader.with(IntArraySource).load(4)
      end

      field :set_scoped_int, ContextQuery, null: false

      def set_scoped_int
        context.scoped_set!("int", object.to_s)
        object.to_s
      end
    end

    class ContextSchema < GraphQL::Schema
      query(ContextQuery)
      lazy_resolve(LazyBlock, :value)
      use GraphQL::Dataloader
    end

    it "can be set and does not leak to sibling fields" do
      query_str = %|
        {
          before: getScopedContext(key: "a")
          firstSetOuter: setScopedContext(key: "a", value: "1") {
            before: getScopedContext(key: "a")
            setInner: setScopedContext(key: "a", value: "2") {
              only: getScopedContext(key: "a")
            }
            after: getScopedContext(key: "a")
          }
          secondSetOuter: setScopedContext(key: "a", value: "3") {
            before: getScopedContext(key: "a")
            setInner: setScopedContext(key: "a", value: "4") {
              only: getScopedContext(key: "a")
            }
            after: getScopedContext(key: "a")
          }
          after: getScopedContext(key: "a")
        }
      |

      expected = {
        'before' => nil,
        'firstSetOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'secondSetOuter' => {
          'before' => '3',
          'setInner' => {
            'only' => '4',
          },
          'after' => '3',
        },
        'after' => nil,
      }
      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "can be set and does not leak to sibling fields when all resolvers are lazy values" do
      query_str = %|
        {
          before: getScopedContext(key: "a", lazy: true)
          setOuter: setScopedContext(key: "a", value: "1", lazy: true) {
            before: getScopedContext(key: "a", lazy: true)
            setInner: setScopedContext(key: "a", value: "2", lazy: true) {
              only: getScopedContext(key: "a", lazy: true)
            }
            after: getScopedContext(key: "a", lazy: true)
          }
          after: getScopedContext(key: "a", lazy: true)
        }
      |
      expected = {
        'before' => nil,
        'setOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'after' => nil,
      }

      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "can be set and does not leak to sibling fields when all get resolvers are lazy values" do
      query_str = %|
        {
          before: getScopedContext(key: "a", lazy: true)
          setOuter: setScopedContext(key: "a", value: "1") {
            before: getScopedContext(key: "a", lazy: true)
            setInner: setScopedContext(key: "a", value: "2") {
              only: getScopedContext(key: "a", lazy: true)
            }
            after: getScopedContext(key: "a", lazy: true)
          }
          after: getScopedContext(key: "a", lazy: true)
        }
      |
      expected = {
        'before' => nil,
        'setOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'after' => nil,
      }

      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "can be set and does not leak to sibling fields when all set resolvers are lazy values" do
      query_str = %|
        {
          before: getScopedContext(key: "a")
          setOuter: setScopedContext(key: "a", value: "1", lazy: true) {
            before: getScopedContext(key: "a")
            setInner: setScopedContext(key: "a", value: "2", lazy: true) {
              only: getScopedContext(key: "a")
            }
            after: getScopedContext(key: "a")
          }
          after: getScopedContext(key: "a")
        }
      |
      expected = {
        'before' => nil,
        'setOuter' => {
          'before' => '1',
          'setInner' => {
            'only' => '2',
          },
          'after' => '1',
        },
        'after' => nil,
      }

      result = ContextSchema.execute(query_str).to_h['data']
      assert_equal(expected, result)
    end

    it "doesn't leak inside lists" do
      query_str = <<-GRAPHQL
      {
        intList {
          before: getScopedContext(key: "int")
          setScopedInt {
            inside: getScopedContext(key: "int")
            inside2: getScopedContext(key: "int_list")
          }
          after: getScopedContext(key: "int")
        }
      }
      GRAPHQL

      expected_data = {"intList"=>
         [{"setScopedInt"=>{"inside"=>"0", "inside2" => "assigned"}, "before"=>nil, "after"=>nil},
          {"setScopedInt"=>{"inside"=>"1", "inside2" => "assigned"}, "before"=>nil, "after"=>nil},
          {"setScopedInt"=>{"inside"=>"2", "inside2" => "assigned"}, "before"=>nil, "after"=>nil},
          {"setScopedInt"=>{"inside"=>"3", "inside2" => "assigned"}, "before"=>nil, "after"=>nil}]}
      result = ContextSchema.execute(query_str)
      assert_equal(expected_data, result["data"])
    end

    it "always retrieves a scoped context value if set" do
      context = GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil)
      dummy_runtime = OpenStruct.new(current_result: nil)
      Fiber[:__graphql_runtime_info] = { context.query => dummy_runtime }
      dummy_runtime.current_result = OpenStruct.new(path: ["somewhere"])
      expected_key = :a
      expected_value = :test

      assert_nil(context[expected_key])
      assert_equal({}, context.to_h)
      refute(context.key?(expected_key))
      assert_raises(KeyError) { context.fetch(expected_key) }
      assert_nil(context.fetch(expected_key, nil))
      assert_nil(context.dig(expected_key))

      context.scoped_merge!(expected_key => nil)
      context[expected_key] = expected_value

      assert_nil(context[expected_key])
      assert_equal({ expected_key => nil }, context.to_h)
      assert(context.key?(expected_key))
      assert_nil(context.fetch(expected_key))
      assert_nil(context.dig(expected_key))

      dummy_runtime.current_result = OpenStruct.new(path: ["something", "new"])

      assert_equal(expected_value, context[expected_key])
      assert_equal({ expected_key => expected_value}, context.to_h)
      assert(context.key?(expected_key))
      assert_equal(expected_value, context.fetch(expected_key))
      assert_equal(expected_value, context.dig(expected_key))

      # Enter a child field:
      dummy_runtime.current_result = OpenStruct.new(path: ["somewhere", "child"])
      assert_nil(context[expected_key])
      assert_equal({ expected_key => nil }, context.to_h)
      assert(context.key?(expected_key))
      assert_nil(context.fetch(expected_key))
      assert_nil(context.dig(expected_key))

      # And a grandchild field
      dummy_runtime.current_result = OpenStruct.new(path: ["somewhere", "child", "grandchild"])
      context.scoped_set!(expected_key, :something_else)
      context.scoped_set!(:another_key, :another_value)
      assert_equal(:something_else, context[expected_key])
      assert_equal({ expected_key => :something_else, another_key: :another_value }, context.to_h)
      assert(context.key?(expected_key))
      assert_equal(:something_else, context.fetch(expected_key))
      assert_equal(:something_else, context.dig(expected_key))
    end

    it "sets a value using #scoped_set!" do
      expected_key = :a
      expected_value = :test

      context = GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil)
      assert_nil(context[expected_key])

      context.scoped_set!(expected_key, expected_value)
      assert_equal(expected_value, context[expected_key])
    end

    it "has a #current_path method" do
      context = GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil)
      current_result = OpenStruct.new(path: ["somewhere", "child", "grandchild"])
      Fiber[:__graphql_runtime_info] = { context.query => OpenStruct.new(current_result: current_result) }
      assert_equal ["somewhere", "child", "grandchild"], context.scoped_context.current_path
    end
  end

  describe "Adding extensions to the response" do
    class ResponseExtensionsSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :with_extension, String

        def with_extension
          context.response_extensions["Something"] = "Something else"
          "OK"
        end
      end
      query(Query)
    end

    it "adds .response_extensions" do
      expected_response = {
        "data" => { "withExtension" => "OK" },
        "extensions" => { "Something" => "Something else" },
      }
      assert_equal(expected_response, ResponseExtensionsSchema.execute("{ withExtension }"))
    end
  end
end
