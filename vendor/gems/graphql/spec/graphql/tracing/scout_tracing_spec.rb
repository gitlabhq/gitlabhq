# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::ScoutTracing do
  module ScoutApmTest
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
      use(GraphQL::Tracing::ScoutTracing)
    end

    class SchemaWithTransactionName < ScoutSchemaBase
      use(GraphQL::Tracing::ScoutTracing, set_transaction_name: true)
    end
  end

  before do
    ScoutApm.clear_all
  end

  it "can leave the transaction name in place" do
    ScoutApmTest::SchemaWithoutTransactionName.execute "query X { int }"
    assert_equal [], ScoutApm::TRANSACTION_NAMES
  end

  it "can override the transaction name" do
    ScoutApmTest::SchemaWithTransactionName.execute "query X { int }"
    assert_equal ["GraphQL/query.X"], ScoutApm::TRANSACTION_NAMES
  end

  it "can override the transaction name per query" do
    # Override with `false`
    ScoutApmTest::SchemaWithTransactionName.execute "{ int }", context: { set_scout_transaction_name: false }
    assert_equal [], ScoutApm::TRANSACTION_NAMES
    # Override with `true`
    ScoutApmTest::SchemaWithoutTransactionName.execute "{ int }", context: { set_scout_transaction_name: true }
    assert_equal ["GraphQL/query.anonymous"], ScoutApm::TRANSACTION_NAMES
  end
end
