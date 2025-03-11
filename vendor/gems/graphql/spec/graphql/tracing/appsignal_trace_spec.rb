# frozen_string_literal: true

require "spec_helper"

module Appsignal
  module_function

  def instrument(key, &block)
    instrumented << key
    yield
  end

  def instrumented
    @instrumented ||= []
  end
end

describe GraphQL::Tracing::AppsignalTrace do
  class IntBox
    def initialize(value)
      @value = value
    end
    attr_reader :value
  end

  module AppsignalTraceTest
    class Thing < GraphQL::Schema::Object
      field :str, String

      def str; "blah"; end
    end

    class Named < GraphQL::Schema::Union
      possible_types Thing
      def self.resolve_type(obj, ctx)
        Thing
      end
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        IntBox.new(1)
      end

      field :thing, Thing
      def thing; :thing; end

      field :named, Named, resolver_method: :thing
    end

    class TestSchema < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::AppsignalTrace)
      lazy_resolve(IntBox, :value)
    end
  end

  before do
    Appsignal.instrumented.clear
  end

  it "traces events" do
    _res = AppsignalTraceTest::TestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
    expected_trace = [
      "execute.graphql",
      "analyze.graphql",
      (USING_C_PARSER ? "lex.graphql" : nil),
      "parse.graphql",
      "validate.graphql",
      "analyze.graphql",
      "execute.graphql",
      "Query.authorized.graphql",
      "Query.thing.graphql",
      "Thing.authorized.graphql",
      "Query.named.graphql",
      "Named.resolve_type.graphql",
      "Thing.authorized.graphql",
      "execute.graphql",
    ].compact
    assert_equal expected_trace, Appsignal.instrumented
  end

  describe "With Datadog Trace" do
    class AppsignalAndDatadogTestSchema < GraphQL::Schema
      query(AppsignalTraceTest::Query)
      trace_with(GraphQL::Tracing::DataDogTrace)
      trace_with(GraphQL::Tracing::AppsignalTrace)
      lazy_resolve(IntBox, :value)
    end

    class AppsignalAndDatadogReverseOrderTestSchema < GraphQL::Schema
      query(AppsignalTraceTest::Query)
      # Include these modules in different order than above:
      trace_with(GraphQL::Tracing::AppsignalTrace)
      trace_with(GraphQL::Tracing::DataDogTrace)
      lazy_resolve(IntBox, :value)
    end


    before do
      Datadog.clear_all
    end

    it "traces with both systems" do
      _res = AppsignalAndDatadogTestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
      expected_appsignal_trace = [
        "execute.graphql",
        (USING_C_PARSER ? "lex.graphql" : nil),
        "parse.graphql",
        "analyze.graphql",
        "validate.graphql",
        "analyze.graphql",
        "execute.graphql",
        "Query.authorized.graphql",
        "Query.thing.graphql",
        "Thing.authorized.graphql",
        "Query.named.graphql",
        "Named.resolve_type.graphql",
        "Thing.authorized.graphql",
        "execute.graphql",
      ].compact

      expected_datadog_trace = [
        "graphql.execute_multiplex",
        (USING_C_PARSER ? "graphql.lex" : nil),
        "graphql.parse",
        "graphql.analyze_multiplex",
        "graphql.validate",
        "graphql.analyze_query",
        "graphql.execute_query",
        "graphql.authorized",
        "graphql.execute_field",
        "graphql.authorized",
        "graphql.execute_field",
        "graphql.resolve_type",
        "graphql.authorized",
        "graphql.execute_query_lazy",
      ].compact

      assert_equal expected_appsignal_trace, Appsignal.instrumented
      assert_equal expected_datadog_trace, Datadog::SPAN_TAGS
        .select { |t| t[0].is_a?(String) }
        .each_slice(2).map { |(p1, p2)| "#{p1[1]}.#{p2[1]}" }
    end

    it "works when the modules are included in reverse order" do
      _res = AppsignalAndDatadogReverseOrderTestSchema.execute("{ int thing { str } named { ... on Thing { str } } }")
      expected_appsignal_trace = [
        (USING_C_PARSER ? "lex.graphql" : nil),
        "parse.graphql",
        "execute.graphql",
        "analyze.graphql",
        "validate.graphql",
        "analyze.graphql",
        "execute.graphql",
        "Query.authorized.graphql",
        "Query.thing.graphql",
        "Thing.authorized.graphql",
        "Query.named.graphql",
        "Named.resolve_type.graphql",
        "Thing.authorized.graphql",
        "execute.graphql",
      ].compact

      expected_datadog_trace = [
        "graphql.execute_multiplex",
        (USING_C_PARSER ? "graphql.lex" : nil),
        "graphql.parse",
        "graphql.analyze_multiplex",
        "graphql.validate",
        "graphql.analyze_query",
        "graphql.execute_query",
        "graphql.authorized",
        "graphql.execute_field",
        "graphql.authorized",
        "graphql.execute_field",
        "graphql.resolve_type",
        "graphql.authorized",
        "graphql.execute_query_lazy",
      ].compact

      assert_equal expected_appsignal_trace, Appsignal.instrumented
      assert_equal expected_datadog_trace, Datadog::SPAN_TAGS
        .select { |t| t[0].is_a?(String) }
        .each_slice(2).map { |(p1, p2)| "#{p1[1]}.#{p2[1]}" }
    end
  end
end
