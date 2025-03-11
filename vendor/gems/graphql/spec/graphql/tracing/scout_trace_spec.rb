# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::ScoutTrace do
  module ScoutApmTraceTest
    class Query < GraphQL::Schema::Object
      include GraphQL::Types::Relay::HasNodeField

      field :int, Integer, null: false

      def int
        1
      end
    end

    class ScoutSchemaBase < GraphQL::Schema
      query(Query)
    end

    class SchemaWithoutTransactionName < ScoutSchemaBase
      trace_with GraphQL::Tracing::ScoutTrace
    end

    class SchemaWithTransactionName < ScoutSchemaBase
      trace_with GraphQL::Tracing::ScoutTrace, set_transaction_name: true
    end
  end

  before do
    ScoutApm.clear_all
  end

  it "can leave the transaction name in place" do
    ScoutApmTraceTest::SchemaWithoutTransactionName.execute "query X { int }"
    assert_equal [], ScoutApm::TRANSACTION_NAMES
  end

  it "can override the transaction name" do
    ScoutApmTraceTest::SchemaWithTransactionName.execute "query X { int }"
    assert_equal ["GraphQL/query.X"], ScoutApm::TRANSACTION_NAMES
  end

  it "can override the transaction name per query" do
    # Override with `false`
    ScoutApmTraceTest::SchemaWithTransactionName.execute "{ int }", context: { set_scout_transaction_name: false }
    assert_equal [], ScoutApm::TRANSACTION_NAMES
    # Override with `true`
    ScoutApmTraceTest::SchemaWithoutTransactionName.execute "{ int }", context: { set_scout_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], ScoutApm::TRANSACTION_NAMES
  end
end
