# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::DataDogTrace do
  module DataDogTraceTest
    class Box
      def initialize(value)
        @value = value
      end
      attr_reader :value
    end

    class Thing < GraphQL::Schema::Object
      field :str, String

      def str; Box.new("blah"); end
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing
      def thing; :thing; end
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::DataDogTrace)
      lazy_resolve(Box, :value)
    end

    class CustomTracerTestSchema < GraphQL::Schema
      module CustomDataDogTracing
        include GraphQL::Tracing::DataDogTrace
        def prepare_span(trace_key, data, span)
          span.set_tag("custom:#{trace_key}", data.keys.sort.join(","))
        end
      end
      query(Query)
      trace_with(CustomDataDogTracing)
      lazy_resolve(Box, :value)
    end
  end

  before do
    Datadog.clear_all
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    DataDogTraceTest::TestSchema.execute("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["Abcd"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    DataDogTraceTest::TestSchema.execute(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["Ab"], Datadog::SPAN_RESOURCE_NAMES
  end

  it "does not set resource if no value can be derived" do
    DataDogTraceTest::TestSchema.execute("{ int }")
    assert_equal [], Datadog::SPAN_RESOURCE_NAMES
  end

  it "sets component and operation tags" do
    DataDogTraceTest::TestSchema.execute("{ int }")
    assert_includes Datadog::SPAN_TAGS, ['component', 'graphql']
    assert_includes Datadog::SPAN_TAGS, ['operation', 'execute_multiplex']
  end

  it "sets custom tags tags" do
    DataDogTraceTest::CustomTracerTestSchema.execute("{ thing { str } }")
    expected_custom_tags = [
      (USING_C_PARSER ? ["custom:lex", "query_string"] : nil),
      ["custom:parse", "query_string"],
      ["custom:execute_multiplex", "multiplex"],
      ["custom:analyze_multiplex", "multiplex"],
      ["custom:validate", "query,validate"],
      ["custom:analyze_query", "query"],
      ["custom:execute_query", "query"],
      ["custom:authorized", "object,query,type"],
      ["custom:execute_field", "arguments,ast_node,field,object,query"],
      ["custom:authorized", "object,query,type"],
      ["custom:execute_query_lazy", "multiplex,query"],
    ].compact

    actual_custom_tags = Datadog::SPAN_TAGS.reject { |t| t[0] == "operation" || t[0] == "component" || t[0].is_a?(Symbol) }
    assert_equal expected_custom_tags, actual_custom_tags
  end
end
