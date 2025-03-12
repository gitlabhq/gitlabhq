# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::PlatformTracing do
  class CustomPlatformTracer < GraphQL::Tracing::PlatformTracing
    TRACE = []

    self.platform_keys = {
      "lex" => "l",
      "parse" => "p",
      "validate" => "v",
      "analyze_query" => "aq",
      "analyze_multiplex" => "am",
      "execute_multiplex" => "em",
      "execute_query" => "eq",
      "execute_query_lazy" => "eql",
    }

    def platform_field_key(type, field)
      "#{type.graphql_name[0]}.#{field.graphql_name[0]}"
    end

    def platform_authorized_key(type)
      "#{type.graphql_name}.authorized"
    end

    def platform_resolve_type_key(type)
      "#{type.graphql_name}.resolve_type"
    end

    def platform_trace(platform_key, key, data)
      TRACE << platform_key
      res = yield
      if res.is_a?(GraphQL::ExecutionError)
        TRACE << "returned error"
      end
      res
    end
  end

  describe "calling a platform tracer" do
    let(:schema) {
      Class.new(Dummy::Schema) { use(CustomPlatformTracer) }
    }

    before do
      CustomPlatformTracer::TRACE.clear
    end

    it "runs the introspection query (handles late-bound types)" do
      assert schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
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

      assert_equal expected_trace, CustomPlatformTracer::TRACE
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
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end

    it "gets execution errors raised from field resolution" do
      scalar_schema = Class.new(Dummy::Schema) { use(CustomPlatformTracer, trace_scalars: true) }
      scalar_schema.execute("{ executionError }")
      assert_includes CustomPlatformTracer::TRACE, "returned error"
    end

    it "traces resolve_type calls" do
      schema.execute(" { favoriteEdible { __typename } }")
      expected_trace = [
          "em",
          "am",
          (USING_C_PARSER ? "l" : nil),
          "p",
          "v",
          "aq",
          "eq",
          "Query.authorized",
          "Q.f",
          "Edible.resolve_type",
          "eql",
          "Edible.resolve_type",
          "Milk.authorized",
          "DynamicFields.authorized",
        ].compact

      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end

    it "traces resolve_type and differentiates field calls on different types" do
      scalar_schema = Class.new(Dummy::Schema) { use(CustomPlatformTracer, trace_scalars: true) }

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

      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end

  describe "by default, scalar fields are not traced" do
    let(:schema) {
      Class.new(Dummy::Schema) {
        use(CustomPlatformTracer)
      }
    }

    before do
      CustomPlatformTracer::TRACE.clear
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
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end

  describe "when scalar fields are traced by default, they are unless specified" do
    let(:schema) {
      Class.new(Dummy::Schema) do
        use(CustomPlatformTracer, trace_scalars: true)
      end
    }

    before do
      CustomPlatformTracer::TRACE.clear
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
      assert_equal expected_trace, CustomPlatformTracer::TRACE
    end
  end
end
