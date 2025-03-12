# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::NewRelicTracing do
  module NewRelicTest
    class Thing < GraphQL::Schema::Object
      implements GraphQL::Types::Relay::Node
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class SchemaWithoutTransactionName < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing)
      orphan_types(Thing)

      def self.object_from_id(_id, _ctx)
        :thing
      end

      def self.resolve_type(_type, _obj, _ctx)
        Thing
      end
    end

    class SchemaWithTransactionName < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing, set_transaction_name: true)
    end

    class SchemaWithScalarTrace < GraphQL::Schema
      query(Query)
      use(GraphQL::Tracing::NewRelicTracing, trace_scalars: true)
    end
  end

  before do
    NewRelic.clear_all
  end

  it "Actually uses the new-style trace under the hood" do
    assert NewRelicTest::SchemaWithoutTransactionName.trace_class_for(:default).ancestors.include?(GraphQL::Tracing::NewRelicTrace)
  end

  it "works with the built-in node field, even though it doesn't have an @owner" do
    res = NewRelicTest::SchemaWithoutTransactionName.execute '{ node(id: "1") { __typename } }'
    assert_equal "Thing", res["data"]["node"]["__typename"]
  end

  it "can leave the transaction name in place" do
    NewRelicTest::SchemaWithoutTransactionName.execute "query X { int }"
    assert_equal [], NewRelic::TRANSACTION_NAMES
  end

  it "can override the transaction name" do
    NewRelicTest::SchemaWithTransactionName.execute "query X { int }"
    assert_equal ["GraphQL/query.X"], NewRelic::TRANSACTION_NAMES
  end

  it "can override the transaction name per query" do
    # Override with `false`
    NewRelicTest::SchemaWithTransactionName.execute "{ int }", context: { set_new_relic_transaction_name: false }
    assert_equal [], NewRelic::TRANSACTION_NAMES
    # Override with `true`
    NewRelicTest::SchemaWithoutTransactionName.execute "{ int }", context: { set_new_relic_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], NewRelic::TRANSACTION_NAMES
  end

  it "falls back to a :tracing_fallback_transaction_name when provided" do
    NewRelicTest::SchemaWithTransactionName.execute("{ int }", context: { tracing_fallback_transaction_name: "Abcd" })
    assert_equal ["GraphQL/query.Abcd"], NewRelic::TRANSACTION_NAMES
  end

  it "does not use the :tracing_fallback_transaction_name if an operation name is present" do
    NewRelicTest::SchemaWithTransactionName.execute(
      "query Ab { int }",
      context: { tracing_fallback_transaction_name: "Cd" }
    )
    assert_equal ["GraphQL/query.Ab"], NewRelic::TRANSACTION_NAMES
  end

  it "does not require a :tracing_fallback_transaction_name even if an operation name is not present" do
    NewRelicTest::SchemaWithTransactionName.execute("{ int }")
    assert_equal ["GraphQL/query.anonymous"], NewRelic::TRANSACTION_NAMES
  end

  it "traces scalars when trace_scalars is true" do
    NewRelicTest::SchemaWithScalarTrace.execute "query X { int }"
    assert_includes NewRelic::EXECUTION_SCOPES, "GraphQL/Query/int"
  end
end
