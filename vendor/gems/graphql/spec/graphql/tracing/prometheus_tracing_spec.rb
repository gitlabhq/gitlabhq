# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::PrometheusTracing do
  module PrometheusTracingTest
    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end
    end

    class Schema < GraphQL::Schema
      query Query
    end
  end

  describe "Observing" do
    it "sends JSON to Prometheus client" do
      client = Minitest::Mock.new

      client.expect :send_json, true do |obj|
        obj[:type] == 'graphql' &&
          obj[:key] == 'execute_field' &&
          obj[:platform_key] == 'Query.int'
      end

      PrometheusTracingTest::Schema.use(
        GraphQL::Tracing::PrometheusTracing,
        client: client,
        trace_scalars: true
      )

      PrometheusTracingTest::Schema.execute "query X { int }"
    end
  end
end
