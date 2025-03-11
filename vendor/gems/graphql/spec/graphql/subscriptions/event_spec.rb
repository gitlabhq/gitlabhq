# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Subscriptions::Event do
  class EventSchema < GraphQL::Schema

    class Query < GraphQL::Schema::Object
    end

    class JsonSubscription < GraphQL::Schema::Subscription
      argument :some_json, GraphQL::Types::JSON, required: false

      field :text, String, null: false
    end

    class Subscription < GraphQL::Schema::Object
      field :json_subscription, subscription: JsonSubscription
    end

    query(Query)
    subscription(Subscription)
  end

  def build_dummy_context(context = {})
    GraphQL::Query.new(EventSchema, "{ __typename }", context: context).context
  end


  it "should serialize a JSON argument into the topic name" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => { "b" => 1, "a" => 0 } }, field: field, context: build_dummy_context, scope: nil)
    assert_equal %Q{:jsonSubscription:someJson:{"a":0,"b":1}}, event.topic
  end

  it "should not serialize the context into the topic name" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    context = build_dummy_context({ my_id: "abc" })
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => { "b" => 1, "a" => 0 } }, field: field, context: context, scope: nil)
    assert_equal %Q{:jsonSubscription:someJson:{"a":0,"b":1}}, event.topic
    assert_equal event.context[:my_id], "abc"
  end

  it "should serialize two equivalent JSON hashes with different key orderings into equivalent topic names" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    event_a = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => { "b" => 1, "a" => 0 } }, field: field, context: build_dummy_context, scope: nil)
    event_b = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => { "a" => 0, "b" => 1 } }, field: field, context: build_dummy_context, scope: nil)
    assert_equal event_a.topic, event_b.topic
  end

  it "should serialize nested hashes into their sorted key forms" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    nested_hash = {
      "b" => 1,
      "c" => {
        "z" => 100,
        "y" => 99
      },
      "a" => 0
    }
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => nested_hash }, field: field, context: build_dummy_context, scope: nil)
    assert_equal %Q{:jsonSubscription:someJson:{"a":0,"b":1,"c":{"y":99,"z":100}}}, event.topic
  end

  it "should serialize a hash inside an array as a sorted hash" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => [{ "b" => 1, "a" => 0 }] }, field: field, context: build_dummy_context, scope: nil)
    assert_equal %Q{:jsonSubscription:someJson:[{"a":0,"b":1}]}, event.topic
  end

  it "should serialize a hash inside an array of an array as a sorted hash" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => [[{ "b" => 1, "a" => 0 }]] }, field: field, context: build_dummy_context, scope: nil)
    assert_equal %Q{:jsonSubscription:someJson:[[{"a":0,"b":1}]]}, event.topic
  end

  it "should serialize a hash inside an array inside of a hash" do
    field = EventSchema.subscription.fields["jsonSubscription"]
    event = GraphQL::Subscriptions::Event.new(name: "test", arguments: { "someJson" => { "key" => [{ "b" => 1, "a" => 0}]} }, field: field, context: build_dummy_context, scope: nil)
    assert_equal %Q{:jsonSubscription:someJson:{"key":[{"a":0,"b":1}]}}, event.topic
  end
end
