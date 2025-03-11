# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::StatsdTracing do
  module MockStatsd
    class << self
      def time(key)
        self.timings << key
        yield
      end

      attr_reader :timings

      def clear
        @timings = []
      end
    end
  end

  class StatsdTestSchema < GraphQL::Schema
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

    query(Query)

    use GraphQL::Tracing::StatsdTracing, statsd: MockStatsd
  end

  before do
    MockStatsd.clear
  end

  it "gathers timings" do
    StatsdTestSchema.execute("query X { int thing { str } }")
    expected_timings = [
      "graphql.execute_multiplex",
      "graphql.analyze_multiplex",
      (USING_C_PARSER ? "graphql.lex" : nil),
      "graphql.parse",
      "graphql.validate",
      "graphql.analyze_query",
      "graphql.execute_query",
      "graphql.authorized.Query",
      "graphql.Query.thing",
      "graphql.authorized.Thing",
      "graphql.execute_query_lazy"
    ].compact
    assert_equal expected_timings, MockStatsd.timings
  end
end
