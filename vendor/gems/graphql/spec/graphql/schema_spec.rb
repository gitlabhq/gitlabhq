# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "inheritance" do
    class DummyFeature1 < GraphQL::Schema::Directive::Feature

    end

    class DummyFeature2 < GraphQL::Schema::Directive::Feature

    end

    class Query < GraphQL::Schema::Object
      field :some_field, String
    end

    class Mutation < GraphQL::Schema::Object
      field :some_field, String
    end

    class Subscription < GraphQL::Schema::Object
      field :some_field, String
    end

    class ExtraType < GraphQL::Schema::Object
    end

    class CustomSubscriptions < GraphQL::Subscriptions::ActionCableSubscriptions
    end

    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        query Query
        mutation Mutation
        subscription Subscription
        max_complexity 1
        max_depth 2
        default_max_page_size 3
        default_page_size 2
        disable_introspection_entry_points
        orphan_types Jazz::Ensemble
        introspection Module.new
        cursor_encoder Object.new
        context_class Class.new
        directives [DummyFeature1]
        extra_types ExtraType
        query_analyzer Object.new
        multiplex_analyzer Object.new
        validate_timeout 100
        max_query_string_tokens 500
        rescue_from(StandardError) { }
        use GraphQL::Backtrace
        use GraphQL::Subscriptions::ActionCableSubscriptions, action_cable: nil, action_cable_coder: JSON
      end
    end

    it "inherits configuration from its superclass" do
      schema = Class.new(base_schema)
      assert_equal base_schema.query, schema.query
      assert_equal base_schema.mutation, schema.mutation
      assert_equal base_schema.subscription, schema.subscription
      assert_equal base_schema.introspection, schema.introspection
      assert_equal base_schema.cursor_encoder, schema.cursor_encoder
      assert_equal base_schema.validate_timeout, schema.validate_timeout
      assert_equal base_schema.max_complexity, schema.max_complexity
      assert_equal base_schema.max_depth, schema.max_depth
      assert_equal base_schema.default_max_page_size, schema.default_max_page_size
      assert_equal base_schema.default_page_size, schema.default_page_size
      assert_equal base_schema.orphan_types, schema.orphan_types
      assert_equal base_schema.context_class, schema.context_class
      assert_equal base_schema.directives, schema.directives
      assert_equal base_schema.max_query_string_tokens, schema.max_query_string_tokens
      assert_equal base_schema.query_analyzers, schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers, schema.multiplex_analyzers
      assert_equal base_schema.disable_introspection_entry_points?, schema.disable_introspection_entry_points?
      expected_plugins = [
        (GraphQL::Schema.use_visibility_profile? ? GraphQL::Schema::Visibility : nil),
        GraphQL::Backtrace,
        GraphQL::Subscriptions::ActionCableSubscriptions
      ].compact
      assert_equal expected_plugins, schema.plugins.map(&:first)
      assert_equal [ExtraType], base_schema.extra_types
      assert_equal [ExtraType], schema.extra_types
      assert_instance_of GraphQL::Subscriptions::ActionCableSubscriptions, schema.subscriptions
      assert_equal GraphQL::Query, schema.query_class
    end

    it "can override configuration from its superclass" do
      custom_query_class = Class.new(GraphQL::Query)
      extra_type_2 = Class.new(GraphQL::Schema::Enum)
      schema = Class.new(base_schema) do
        use CustomSubscriptions, action_cable: nil, action_cable_coder: JSON
        query_class(custom_query_class)
        extra_types [extra_type_2]
        max_query_string_tokens nil
      end

      query = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :some_field, String
      end
      schema.query(query)
      mutation = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Mutation'
        field :some_field, String
      end
      schema.mutation(mutation)
      subscription = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Subscription'
        field :some_field, String
      end
      schema.subscription(subscription)
      introspection = Module.new
      schema.introspection(introspection)
      cursor_encoder = Object.new
      schema.cursor_encoder(cursor_encoder)

      context_class = Class.new
      schema.context_class(context_class)
      schema.validate_timeout(10)
      schema.max_complexity(10)
      schema.max_depth(20)
      schema.default_max_page_size(30)
      schema.default_page_size(15)
      schema.orphan_types(Jazz::InstrumentType)
      schema.directives([DummyFeature2])
      query_analyzer = Object.new
      schema.query_analyzer(query_analyzer)
      multiplex_analyzer = Object.new
      schema.multiplex_analyzer(multiplex_analyzer)
      schema.rescue_from(GraphQL::ExecutionError)

      assert_equal query, schema.query
      assert_equal mutation, schema.mutation
      assert_equal subscription, schema.subscription
      assert_equal introspection, schema.introspection
      assert_equal cursor_encoder, schema.cursor_encoder
      assert_nil schema.max_query_string_tokens

      assert_equal context_class, schema.context_class
      assert_equal 10, schema.validate_timeout
      assert_equal 10, schema.max_complexity
      assert_equal 20, schema.max_depth
      assert_equal 30, schema.default_max_page_size
      assert_equal 15, schema.default_page_size
      assert_equal [Jazz::Ensemble, Jazz::InstrumentType], schema.orphan_types
      assert_equal schema.directives, GraphQL::Schema.default_directives.merge(DummyFeature1.graphql_name => DummyFeature1, DummyFeature2.graphql_name => DummyFeature2)
      assert_equal base_schema.query_analyzers + [query_analyzer], schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers + [multiplex_analyzer], schema.multiplex_analyzers
      expected_plugins = [GraphQL::Backtrace, GraphQL::Subscriptions::ActionCableSubscriptions, CustomSubscriptions]
      if GraphQL::Schema.use_visibility_profile?
        expected_plugins.unshift(GraphQL::Schema::Visibility)
      end
      assert_equal expected_plugins, schema.plugins.map(&:first)
      assert_equal custom_query_class, schema.query_class
      assert_equal [ExtraType, extra_type_2], schema.extra_types
      assert_instance_of CustomSubscriptions, schema.subscriptions
    end
  end

  class ExampleOptionEnum < GraphQL::Schema::Enum
  end
  it "rejects non-object types to orphan_types" do
    object_type = Class.new(GraphQL::Schema::Object)
    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema) do
        orphan_types(ExampleOptionEnum, object_type)
      end
    end

    expected_msg = "Only object type classes should be added as `orphan_types(...)`.

- Remove these no-op types from `orphan_types`: ExampleOptionEnum (ENUM)
- See https://graphql-ruby.org/type_definitions/interfaces.html#orphan-types

To add other types to your schema, you might want `extra_types`: https://graphql-ruby.org/schema/definition.html#extra-types
"
    assert_equal expected_msg, err.message
  end

  describe ".references_to" do
    it "doesn't include any duplicates" do
      [Dummy::Schema, Jazz::Schema].each do |schema_class|
        schema_class.references_to.each do |referent, references|
          ref_paths = references.map { |r| "#{r.class}/#{r.path}"}.sort
          assert_equal ref_paths.uniq, ref_paths, "#{schema_class}.references_to has unique entries for `#{referent}`"
        end
      end
    end
  end

  describe "merged, inherited caches" do
    METHODS_TO_CACHE = {
      types: 1,
      union_memberships: 1,
      possible_types: 5, # The number of types with fields accessed in the query
    }

    let(:schema) do
      Class.new(Dummy::Schema) do
        def self.reset_calls
          @calls = Hash.new(0)
          @callers = Hash.new { |h, k| h[k] = [] }
        end

        METHODS_TO_CACHE.each do |method_name, allowed_calls|
          define_singleton_method(method_name) do |*args, **kwargs, &block|
            if @calls
              call_count = @calls[method_name] += 1
              @callers[method_name] << caller
            else
              call_count = 0
            end
            if call_count > allowed_calls
              raise "Called #{method_name} more than #{allowed_calls} times, previous caller: \n#{@callers[method_name].first.join("\n")}"
            end
            super(*args, **kwargs, &block)
          end
        end
      end
    end

    it "caches #{METHODS_TO_CACHE.keys} at runtime" do
      query_str = "
        query getFlavor($cheeseId: Int!) {
          brie: cheese(id: 1)   { ...cheeseFields, taste: flavor },
          cheese(id: $cheeseId)  {
            __typename,
            id,
            ...cheeseFields,
            ... edibleFields,
            ... on Cheese { cheeseKind: flavor },
          }
          fromSource(source: COW) { id }
          fromSheep: fromSource(source: SHEEP) { id }
          firstSheep: searchDairy(product: [{source: SHEEP}]) {
            __typename,
            ... dairyFields,
            ... milkFields
          }
          favoriteEdible { __typename, fatContent }
        }
        fragment cheeseFields on Cheese { flavor }
        fragment edibleFields on Edible { fatContent }
        fragment milkFields on Milk { source }
        fragment dairyFields on AnimalProduct {
           ... on Cheese { flavor }
           ... on Milk   { source }
        }
      "
      schema.reset_calls
      res = schema.execute(query_str,  variables: { cheeseId: 2 })
      assert_equal "Brie", res["data"]["brie"]["flavor"]
    end
  end

  describe "`use` works with plugins that attach instrumentation, trace modules, query analyzers" do
    module NoOpTrace
      def execute_query(query:)
        query.context[:no_op_trace_ran_before_query] = true
        super
      ensure
        query.context[:no_op_trace_ran_after_query] = true
      end
    end

    class NoOpAnalyzer < GraphQL::Analysis::Analyzer
      def initialize(query_or_multiplex)
        query_or_multiplex.context[:no_op_analyzer_ran_initialize] = true
        super
      end

      def on_leave_field(_node, _parent, visitor)
        visitor.query.context[:no_op_analyzer_ran_on_leave_field] = true
      end

      def result
        query.context[:no_op_analyzer_ran_result] = true
      end
    end

    module PluginWithInstrumentationTracingAndAnalyzer
      def self.use(schema_defn)
        schema_defn.trace_with(NoOpTrace)
        schema_defn.query_analyzer NoOpAnalyzer
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Query'
      field :foobar, Integer, null: false
      def foobar; 1337; end
    end

    describe "when called on class definitions" do
      let(:schema) do
        Class.new(GraphQL::Schema) do
          query query_type
          use PluginWithInstrumentationTracingAndAnalyzer
        end
      end

      let(:query) { GraphQL::Query.new(schema, "query { foobar }") }

      it "attaches plugins correctly, runs all of their callbacks" do
        res = query.result
        assert res.key?("data")

        assert_equal true, query.context[:no_op_trace_ran_before_query]
        assert_equal true, query.context[:no_op_trace_ran_after_query]
        assert_equal true, query.context[:no_op_analyzer_ran_initialize]
        assert_equal true, query.context[:no_op_analyzer_ran_on_leave_field]
        assert_equal true, query.context[:no_op_analyzer_ran_result]
      end
    end

    describe "when called on schema subclasses" do
      let(:schema) do
        schema = Class.new(GraphQL::Schema) do
          query query_type
        end

        # return a subclass
        Class.new(schema) do
          use PluginWithInstrumentationTracingAndAnalyzer
        end
      end

      let(:query) { GraphQL::Query.new(schema, "query { foobar }") }

      it "attaches plugins correctly, runs all of their callbacks" do
        res = query.result
        assert res.key?("data")

        assert_equal true, query.context[:no_op_trace_ran_before_query]
        assert_equal true, query.context[:no_op_trace_ran_after_query]
        assert_equal true, query.context[:no_op_analyzer_ran_initialize]
        assert_equal true, query.context[:no_op_analyzer_ran_on_leave_field]
        assert_equal true, query.context[:no_op_analyzer_ran_result]
      end
    end
  end

  describe ".new_trace" do
    module NewTrace1
      def initialize(**opts)
        @trace_opts = opts
      end

      attr_reader :trace_opts
    end

    module NewTrace2
    end

    it "returns an instance of the configured trace_class with trace_options" do
      parent_schema = Class.new(GraphQL::Schema) do
        trace_with NewTrace1, a: 1
      end

      child_schema = Class.new(parent_schema) do
        trace_with NewTrace2, b: 2
      end

      parent_trace = parent_schema.new_trace
      assert_equal({a: 1}, parent_trace.trace_opts)
      assert_kind_of NewTrace1, parent_trace
      refute_kind_of NewTrace2, parent_trace
      assert_kind_of GraphQL::Tracing::Trace, parent_trace

      child_trace = child_schema.new_trace
      assert_equal({a: 1, b: 2}, child_trace.trace_opts)
      assert_kind_of NewTrace1, child_trace
      assert_kind_of NewTrace2, child_trace
      assert_kind_of GraphQL::Tracing::Trace, child_trace
    end

    it "returns an instance of the parent configured trace_class with trace_options" do
      parent_schema = Class.new(GraphQL::Schema) do
        trace_with NewTrace1, a: 1
      end

      child_schema = Class.new(parent_schema) do
      end

      child_trace = child_schema.new_trace
      assert_equal({a: 1}, child_trace.trace_opts)
      assert_kind_of NewTrace1, child_trace
      assert_kind_of GraphQL::Tracing::Trace, child_trace
    end
  end

  describe ".possible_types" do
    it "returns a single item for objects" do
      assert_equal [Dummy::Cheese], Dummy::Schema.possible_types(Dummy::Cheese)
    end

    it "returns empty for abstract types without any possible types" do
      unknown_union = Class.new(GraphQL::Schema::Union) { graphql_name("Unknown") }
      assert_equal [], Dummy::Schema.possible_types(unknown_union)
    end

    it "returns correct types for interfaces based on the context" do
      assert_equal [], Jazz::Schema.possible_types(Jazz::PrivateNameEntity, { private: false })
      assert_equal [Jazz::Ensemble], Jazz::Schema.possible_types(Jazz::PrivateNameEntity, { private: true })
    end

    it "returns correct types for unions based on the context" do
      assert_equal [Jazz::Musician], Jazz::Schema.possible_types(Jazz::PerformingAct, { hide_ensemble: true })
      assert_equal [Jazz::Musician, Jazz::Ensemble], Jazz::Schema.possible_types(Jazz::PerformingAct, { hide_ensemble: false })
    end
  end

  describe 'validate' do
    let(:schema) { Dummy::Schema}

    describe 'validate' do
      it 'validates valid query ' do
        query = "query sample { root }"

        errors = schema.validate(query)

        assert_empty errors
      end

      it 'validates invalid query ' do
        query = "query sample { invalid }"

        errors = schema.validate(query)

        assert_equal(1, errors.size)
      end
    end
  end

  describe "requiring query" do
    class QueryRequiredSchema < GraphQL::Schema
    end
    it "returns an error if no query type is defined" do
      res = QueryRequiredSchema.execute("{ blah }")
      assert_equal ["Schema is not configured for queries"], res["errors"].map { |e| e["message"] }
    end
  end

  describe ".as_json" do
    it "accepts options for the introspection query" do
      introspection_schema = Class.new(Dummy::Schema) do
        max_depth 20
      end
      default_res = introspection_schema.as_json
      refute default_res["data"]["__schema"].key?("description")
      directives = default_res["data"]["__schema"]["directives"]
      refute directives.first.key?("isRepeatable")
      refute default_res["data"]["__schema"]["types"].find { |t| t["kind"] == "SCALAR" }.key?("specifiedByURL")
      refute default_res["data"]["__schema"]["types"].find { |t| t["kind"] == "INPUT_OBJECT" }.key?("isOneOf")
      assert_includes default_res.to_s, "oldSource"

      full_res = introspection_schema.as_json(
        include_deprecated_args: false,
        include_is_one_of: true,
        include_is_repeatable: true,
        include_schema_description: true,
        include_specified_by_url: true,
      )

      assert full_res["data"]["__schema"].key?("description")
      directives = full_res["data"]["__schema"]["directives"]
      assert directives.first.key?("isRepeatable")
      assert full_res["data"]["__schema"]["types"].find { |t| t["kind"] == "SCALAR" }.key?("specifiedByURL")
      assert full_res["data"]["__schema"]["types"].find { |t| t["kind"] == "INPUT_OBJECT" }.key?("isOneOf")
      refute_includes full_res.to_s, "oldSource"
    end
  end

  it "starts with no references_to" do
    assert_equal({}, GraphQL::Schema.references_to)
  end

  describe "DidYouMean support" do
    class DidYouMeanSchema < GraphQL::Schema
      class ExampleEnum < GraphQL::Schema::Enum
        value "VALUE_ONE", "The first value"
        value "VALUE_TWO", "The second value"
      end

      class Query < GraphQL::Schema::Object
        field :first_field, String
        field :second_field, String
        field :second_fiel, String
        field :scond_field, String
        field :third_field, ExampleEnum
      end

      query(Query)
    end

    it "returns helpful messages" do
      res = DidYouMeanSchema.execute("{ first_field }")
      assert_equal ["Field 'first_field' doesn't exist on type 'Query' (Did you mean `firstField`?)"], res["errors"].map { |err| err["message"] }

      res = DidYouMeanSchema.execute("{ seconField }")
      assert_equal ["Field 'seconField' doesn't exist on type 'Query' (Did you mean `secondFiel`, `secondField` or `scondField`?)"], res["errors"].map { |err| err["message"] }
    end

    it "can disable those messages" do
      no_dym_schema = Class.new(DidYouMeanSchema) do
        did_you_mean(nil)
      end
      res = no_dym_schema.execute("{ first_field }")
      assert_equal ["Field 'first_field' doesn't exist on type 'Query'"], res["errors"].map { |err| err["message"] }

      res = no_dym_schema.execute("{ seconField }")
      assert_equal ["Field 'seconField' doesn't exist on type 'Query'"], res["errors"].map { |err| err["message"] }
    end

    it "returns helpful message when non existing field is queried on a non-fields type" do
      res = DidYouMeanSchema.execute("{ thirdField { foo } }")
      assert_equal ["Selections can't be made on enums (field 'thirdField' returns ExampleEnum but has selections [\"foo\"])"], res["errors"].map { |err| err["message"] }

      res = DidYouMeanSchema.execute("{ secondField { foo } }")
      assert_equal ["Selections can't be made on scalars (field 'secondField' returns String but has selections [\"foo\"])"], res["errors"].map { |err| err["message"] }
    end
  end

  it "defers root type blocks until those types are used" do
    calls = []
    schema = Class.new(GraphQL::Schema) do
      use(GraphQL::Schema::Visibility)
      query { calls << :query; Class.new(GraphQL::Schema::Object) { graphql_name("Query") } }
      mutation { calls << :mutation; Class.new(GraphQL::Schema::Object) { graphql_name("Mutation") } }
      subscription { calls << :subscription; Class.new(GraphQL::Schema::Object) { graphql_name("Subscription") } }
      # Test this because it tries to modify `subscription` -- currently hardcoded in Schema.add_subscription_extension_if_necessary
      use GraphQL::Subscriptions
    end

    assert_equal [], calls
    assert_equal "Query", schema.query.graphql_name
    assert_equal [:query], calls
    assert_equal "Mutation", schema.mutation.graphql_name
    assert_equal [:query, :mutation], calls
    assert_equal "Subscription", schema.subscription.graphql_name
    assert_equal [:query, :mutation, :subscription], calls
    assert schema.instance_variable_get(:@subscription_extension_added)
  end

  it "adds the subscription extension if subscription(...) is called second" do
    schema = Class.new(GraphQL::Schema) do
      use GraphQL::Subscriptions
      subscription(Class.new(GraphQL::Schema::Object) { graphql_name("Subscription") })
    end
    assert schema.subscription
    assert schema.instance_variable_get(:@subscription_extension_added)

    schema2 = Class.new(GraphQL::Schema) do
      use(GraphQL::Schema::Visibility)
      use GraphQL::Subscriptions
      subscription(Class.new(GraphQL::Schema::Object) { graphql_name("Subscription") })
    end
    assert schema2.subscription
    assert schema2.instance_variable_get(:@subscription_extension_added)
  end

  describe "backtrace error handling" do
    class CustomError < RuntimeError; end
    class Query < GraphQL::Schema::Object
      field :test, Integer, null: false

      def test
        raise CustomError
      end
    end

    it "raises a TracedError when backtrace is enabled" do
      schema = Class.new(GraphQL::Schema) do
        query(Query)
        use GraphQL::Backtrace
      end
      query_str = '{ test }'

      assert_raises(GraphQL::Backtrace::TracedError) do
        schema.execute(query_str)
      end
    end

    it "rescues them when using rescue_from with backtrace" do
      schema = Class.new(GraphQL::Schema) do
        query(Query)
        use GraphQL::Backtrace

        rescue_from(CustomError) do
          raise GraphQL::ExecutionError.new('Handled CustomError')
        end
      end
      query_str = '{ test }'
      expected_errors = [
        {
          'message' => 'Handled CustomError',
          'locations' => [{'line' => 1, 'column' => 3}],
          'path' => ['test']
        }
      ]

      assert_equal expected_errors, schema.execute(query_str).to_h['errors']
    end
  end
end
