# frozen_string_literal: true
require "spec_helper"
require_relative "./appsignal_trace_spec"
require_relative "./statsd_trace_spec"
describe GraphQL::Tracing::PlatformTrace do
  module CustomPlatformTrace
    include GraphQL::Tracing::PlatformTrace
    TRACE = []

    {
      "lex" => "l",
      "parse" => "p",
      "validate" => "v",
      "analyze_query" => "aq",
      "analyze_multiplex" => "am",
      "execute_multiplex" => "em",
      "execute_query" => "eq",
      "execute_query_lazy" => "eql",
    }.each do |method_name, trace_key|
      define_method(method_name) do |**data, &block|
        TRACE << trace_key
        block.call
      end
    end

    def platform_authorized(platform_key)
      TRACE << platform_key
      yield
    end

    def platform_resolve_type(platform_key)
      TRACE << platform_key
      yield
    end

    def platform_execute_field(platform_key)
      TRACE << platform_key
      res = yield
      if res.is_a?(GraphQL::ExecutionError)
        TRACE << "returned error"
      end
      res
    end

    def platform_field_key(field)
      "#{field.owner.graphql_name[0]}.#{field.graphql_name[0]}"
    end

    def platform_authorized_key(type)
      "#{type.graphql_name}.authorized"
    end

    def platform_resolve_type_key(type)
      "#{type.graphql_name}.resolve_type"
    end
  end

  describe "calling a platform tracer" do
    let(:schema) {
      Class.new(Dummy::Schema) { trace_with(CustomPlatformTrace) }
    }

    before do
      CustomPlatformTrace::TRACE.clear
    end

    it "runs the introspection query (handles late-bound types)" do
      assert schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    end

    it "gets execution errors raised from field resolution" do
      scalar_schema = Class.new(Dummy::Schema) { trace_with(CustomPlatformTrace, trace_scalars: true) }
      scalar_schema.execute("{ executionError }")
      assert_includes CustomPlatformTrace::TRACE, "returned error"
    end

    it "calls the platform's own method with its own keys" do
      schema.execute(" { cheese(id: 1) { flavor } }")
      expected_trace = [
          "em",
          "am",
          (USING_C_PARSER ? "l" : nil),
          "p",
          "v",
          "aq",
          "eq",
          "Query.authorized",
          "Q.c", # notice that the flavor is skipped
          "Cheese.authorized",
          "eql",
          "Cheese.authorized", # This is the lazy part, calling the proc
        ].compact

      assert_equal expected_trace, CustomPlatformTrace::TRACE
    end

    it "traces during Query#result" do
      query_str = "{ cheese(id: 1) { flavor } }"
      expected_trace = [
        # This is from the extra validation
        "v",
        "em",
        "am",
        (USING_C_PARSER ? "l" : nil),
        "p",
        "v",
        "aq",
        "eq",
        "Query.authorized",
        "Q.c", # notice that the flavor is skipped
        "Cheese.authorized",
        "eql",
        "Cheese.authorized", # This is the lazy part, calling the proc
    ].compact

      query = GraphQL::Query.new(schema, query_str)
      # First, validate
      schema.validate(query.query_string)
      # Then execute
      query.result
      assert_equal expected_trace, CustomPlatformTrace::TRACE
    end

    it "traces resolve_type and differentiates field calls on different types" do
      scalar_schema = Class.new(Dummy::Schema) { trace_with(CustomPlatformTrace, trace_scalars: true) }
      scalar_schema.execute(" { allEdible { __typename fatContent } }")
      expected_trace = [
          "em",
          "am",
          (USING_C_PARSER ? "l" : nil),
          "p",
          "v",
          "aq",
          "eq",
          "Query.authorized",
          "Q.a",
          "Edible.resolve_type",
          "Edible.resolve_type",
          "Edible.resolve_type",
          "Edible.resolve_type",
          "eql",
          "Edible.resolve_type",
          "Cheese.authorized",
          "Cheese.authorized",
          "DynamicFields.authorized",
          "D._",
          "C.f",
          "Edible.resolve_type",
          "Cheese.authorized",
          "Cheese.authorized",
          "DynamicFields.authorized",
          "D._",
          "C.f",
          "Edible.resolve_type",
          "Cheese.authorized",
          "Cheese.authorized",
          "DynamicFields.authorized",
          "D._",
          "C.f",
          "Edible.resolve_type",
          "Milk.authorized",
          "DynamicFields.authorized",
          "D._",
          "E.f",
        ].compact

      assert_equal expected_trace, CustomPlatformTrace::TRACE
    end
  end

  describe "by default, scalar fields are not traced" do
    let(:schema) {
      Class.new(Dummy::Schema) {
        trace_with(CustomPlatformTrace)
      }
    }

    before do
      CustomPlatformTrace::TRACE.clear
    end

    it "only traces traceTrue, not traceFalse or traceNil" do
      schema.execute(" { tracingScalar { traceNil traceFalse traceTrue } }")
      expected_trace = [
          "em",
          "am",
          (USING_C_PARSER ? "l" : nil),
          "p",
          "v",
          "aq",
          "eq",
          "Query.authorized",
          "Q.t",
          "TracingScalar.authorized",
          "T.t",
          "eql",
      ].compact
      assert_equal expected_trace, CustomPlatformTrace::TRACE
    end
  end

  describe "when scalar fields are traced by default, they are unless specified" do
    let(:schema) {
      Class.new(Dummy::Schema) do
        trace_with(CustomPlatformTrace, trace_scalars: true)
      end
    }

    before do
      CustomPlatformTrace::TRACE.clear
    end

    it "traces traceTrue and traceNil but not traceFalse" do
      schema.execute(" { tracingScalar { traceNil traceFalse traceTrue } }")
      expected_trace = [
          "em",
          "am",
          (USING_C_PARSER ? "l" : nil),
          "p",
          "v",
          "aq",
          "eq",
          "Query.authorized",
          "Q.t",
          "TracingScalar.authorized",
          "T.t",
          "T.t",
          "eql",
        ].compact
      assert_equal expected_trace, CustomPlatformTrace::TRACE
    end
  end

  describe "using subclasses altogether" do
    class KitchenSinkTraceSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :int, Int, fallback_value: 1
      end

      query(Query)

      trace_with GraphQL::Tracing::DataDogTrace
      trace_with GraphQL::Tracing::SentryTrace
      trace_with GraphQL::Tracing::PrometheusTrace, client: Minitest::Mock.new
      trace_with GraphQL::Tracing::ScoutTrace
      trace_with GraphQL::Tracing::AppsignalTrace
      trace_with GraphQL::Tracing::NewRelicTrace
      trace_with GraphQL::Tracing::StatsdTrace, statsd: TraceMockStatsd
    end

    before do
      TraceMockStatsd.clear
    end

    it "doesn't crash" do
      res = KitchenSinkTraceSchema.execute("{ int }")
      assert_equal 1, res["data"]["int"]
    end
  end
end
