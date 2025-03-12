# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::SentryTrace do
  module SentryTraceTest
    class Thing < GraphQL::Schema::Object
      field :str, String
      def str; "blah"; end
    end

    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end

      field :thing, Thing
      def thing; :thing; end
    end

    class SchemaWithoutTransactionName < GraphQL::Schema
      query(Query)

      module OtherTrace
        def execute_query(query:)
          query.context[:other_trace_ran] = true
          super
        end
      end
      trace_with OtherTrace
      trace_with GraphQL::Tracing::SentryTrace
    end

    class SchemaWithTransactionName < GraphQL::Schema
      query(Query)
      trace_with(GraphQL::Tracing::SentryTrace, set_transaction_name: true)
    end
  end

  before do
    Sentry.clear_all
  end

  it "works with other trace modules" do
    res = SentryTraceTest::SchemaWithoutTransactionName.execute("{ int }")
    assert res.context[:other_trace_ran]
  end

  describe "When Sentry is not configured" do
    it "does not initialize any spans" do
      Sentry.stub(:initialized?, false) do
        SentryTraceTest::SchemaWithoutTransactionName.execute("{ int thing { str } }")
        assert_equal [], Sentry::SPAN_DATA
        assert_equal [], Sentry::SPAN_DESCRIPTIONS
        assert_equal [], Sentry::SPAN_OPS
      end
    end
  end

  describe "When Sentry.with_child_span returns nil" do
    it "does not initialize any spans" do
      Sentry.stub(:with_child_span, nil) do
        SentryTraceTest::SchemaWithoutTransactionName.execute("{ int thing { str } }")
        assert_equal [], Sentry::SPAN_DATA
        assert_equal [], Sentry::SPAN_DESCRIPTIONS
        assert_equal [], Sentry::SPAN_OPS
      end
    end
  end

  it "sets the expected spans" do
    SentryTraceTest::SchemaWithoutTransactionName.execute("{ int thing { str } }")
    expected_span_ops = [
      "graphql.execute_multiplex",
      "graphql.analyze_multiplex",
      (USING_C_PARSER ? "graphql.lex" : nil),
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze",
      "graphql.execute",
      "graphql.authorized.Query",
      "graphql.field.Query.thing",
      "graphql.authorized.Thing",
      "graphql.execute"
    ].compact

    assert_equal expected_span_ops, Sentry::SPAN_OPS
  end

  it "sets span descriptions for an anonymous query" do
    SentryTraceTest::SchemaWithoutTransactionName.execute("{ int }")

    assert_equal ["query", "query"], Sentry::SPAN_DESCRIPTIONS
  end

  it "sets span data for an anonymous query" do
    SentryTraceTest::SchemaWithoutTransactionName.execute("{ int }")
    expected_span_data = [
      ["graphql.document", "{ int }"],
      ["graphql.operation.type", "query"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end

  it "sets span descriptions for a named query" do
    SentryTraceTest::SchemaWithoutTransactionName.execute("query Ab { int }")

    assert_equal ["query Ab", "query Ab"], Sentry::SPAN_DESCRIPTIONS
  end

  it "sets span data for a named query" do
    SentryTraceTest::SchemaWithoutTransactionName.execute("query Ab { int }")
    expected_span_data = [
      ["graphql.document", "query Ab { int }"],
      ["graphql.operation.name", "Ab"],
      ["graphql.operation.type", "query"]
    ].compact

    assert_equal expected_span_data.sort, Sentry::SPAN_DATA.sort
  end

  it "can leave the transaction name in place" do
    SentryTraceTest::SchemaWithoutTransactionName.execute "query X { int }"
    assert_equal [], Sentry::TRANSACTION_NAMES
  end

  it "can override the transaction name" do
    SentryTraceTest::SchemaWithTransactionName.execute "query X { int }"
    assert_equal ["GraphQL/query.X"], Sentry::TRANSACTION_NAMES
  end

  it "can override the transaction name per query" do
    # Override with `false`
    SentryTraceTest::SchemaWithTransactionName.execute "{ int }", context: { set_sentry_transaction_name: false }
    assert_equal [], Sentry::TRANSACTION_NAMES
    # Override with `true`
    SentryTraceTest::SchemaWithoutTransactionName.execute "{ int }", context: { set_sentry_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], Sentry::TRANSACTION_NAMES
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    SentryTraceTest::SchemaWithTransactionName.execute("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["GraphQL/query.Abcd"], Sentry::TRANSACTION_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    SentryTraceTest::SchemaWithTransactionName.execute(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["GraphQL/query.Ab"], Sentry::TRANSACTION_NAMES
  end

  it "does not require a :tracing_fallback_transaction_name even if an operation name is not present" do
    SentryTraceTest::SchemaWithTransactionName.execute("{ int }")
    assert_equal ["GraphQL/query.anonymous"], Sentry::TRANSACTION_NAMES
  end
end
