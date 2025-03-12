# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::NotificationsTrace do
  module NotificationsTraceTest
    class Query < GraphQL::Schema::Object
      field :int, Integer, null: false

      def int
        1
      end
    end

    class DummyEngine
      def self.dispatched_events
        @dispatched_events ||= []
      end

      def self.instrument(event, payload)
        dispatched_events << [event, payload]
        yield if block_given?
      end
    end

    module OtherTrace
      def execute_query(query:)
        query.context[:other_trace_ran] = true
        super
      end
    end

    class Schema < GraphQL::Schema
      query Query
      trace_with OtherTrace
      trace_with GraphQL::Tracing::NotificationsTrace, engine: DummyEngine
    end
  end

  before do
    NotificationsTraceTest::DummyEngine.dispatched_events.clear
  end


  describe "Observing" do
    it "dispatches the event to the notifications engine with suffixed key" do
      NotificationsTraceTest::Schema.execute "query X { int }"
      dispatched_events = NotificationsTraceTest::DummyEngine.dispatched_events.to_h
      expected_event_keys = [
        'execute_multiplex.graphql',
        'analyze_multiplex.graphql',
        (USING_C_PARSER ? 'lex.graphql' : nil),
        'parse.graphql',
        'validate.graphql',
        'analyze_query.graphql',
        'execute_query.graphql',
        'authorized.graphql',
        'execute_field.graphql',
        'execute_query_lazy.graphql'
      ].compact

      assert_equal expected_event_keys, dispatched_events.keys

      dispatched_events.each do |event, payload|
        assert event.end_with?(".graphql")
        assert payload.is_a?(Hash)
      end
    end

    it "works with other tracers" do
      res = NotificationsTraceTest::Schema.execute "query X { int }"
      assert res.context[:other_trace_ran]
    end
  end
end
