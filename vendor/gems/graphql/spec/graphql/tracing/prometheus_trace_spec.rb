# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::PrometheusTracing do
  module PrometheusTraceTest
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

      PrometheusTraceTest::Schema.trace_with GraphQL::Tracing::PrometheusTrace,
        client: client,
        trace_scalars: true

        PrometheusTraceTest::Schema.execute "query X { int }"
    end
  end
end
