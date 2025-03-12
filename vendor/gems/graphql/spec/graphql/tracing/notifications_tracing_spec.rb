# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::NotificationsTracing do
  module NotificationsTracingTest
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
    it "dispatches the event to the notifications engine with suffixed key" do
      dispatched_events = trigger_fake_notifications_tracer(NotificationsTracingTest::Schema)

      assert dispatched_events.length > 0

      dispatched_events.each do |event, payload|
        assert event.end_with?(".graphql")
        assert payload.is_a?(Hash)
      end
    end
  end

  def trigger_fake_notifications_tracer(schema)
    dispatched_events = []
    engine = Object.new

    engine.define_singleton_method(:instrument) do |event, payload, &blk|
      dispatched_events << [event, payload]
      blk.call if blk
    end

    tracer = GraphQL::Tracing::NotificationsTracing.new(engine)
    schema.tracer(tracer, silence_deprecation_warning: true)
    schema.execute "query X { int }"

    dispatched_events
  end
end
