# frozen_string_literal: true
require "spec_helper"

class InMemoryBackend
  MAX_COMPLEXITY = 5
  class Subscriptions < GraphQL::Subscriptions
    attr_reader :deliveries, :pushes, :extra, :queries, :events

    def initialize(schema:, extra:, **rest)
      super
      @extra = extra
      @queries = {}
      # { topic => { fingerprint => [sub_id, ... ] } }
      @events = Hash.new { |h,k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
      @deliveries = Hash.new { |h, k| h[k] = [] }
      @pushes = []
    end

    def write_subscription(query, events)
      subscription_id = query.context[:subscription_id] = build_id
      @queries[subscription_id] = query
      events.each do |ev|
        @events[ev.topic][ev.fingerprint] << subscription_id
      end
    end

    def read_subscription(subscription_id)
      query = @queries[subscription_id]
      if query
        {
          query_string: query.query_string,
          operation_name: query.operation_name,
          variables: query.provided_variables,
          context: {
            me: query.context[:me],
            validate_update: query.context[:validate_update],
            other_int: query.context[:other_int],
            hidden_event: query.context[:hidden_event],
            shared_stream: query.context[:shared_stream],
          },
          transport: :socket,
        }
      else
        nil
      end
    end

    def delete_subscription(subscription_id)
      @queries.delete(subscription_id)
      @events.each do |topic, sub_ids_by_fp|
        sub_ids_by_fp.each do |fp, sub_ids|
          sub_ids.delete(subscription_id)
          if sub_ids.empty?
            sub_ids_by_fp.delete(fp)
            if sub_ids_by_fp.empty?
              @events.delete(topic)
            end
          end
        end
      end
    end

    def execute_all(event, object)
      topic = event.topic
      sub_ids_by_fp = @events[topic]
      sub_ids_by_fp.each do |fingerprint, sub_ids|
        result = execute_update(sub_ids.first, event, object)
        if !result.nil?
          sub_ids.each do |sub_id|
            deliver(sub_id, result)
          end
        end
      end
    end

    def deliver(subscription_id, result)
      query = @queries[subscription_id]
      socket = query.context[:socket] || subscription_id
      @deliveries[socket] << result
    end

    def execute_update(subscription_id, event, object)
      query = @queries[subscription_id]
      if query
        @pushes << query.context[:socket]
      end
      super
    end

    # Just for testing:
    def reset
      @queries.clear
      @events.clear
      @deliveries.clear
      @pushes.clear
    end
  end

  # Just a random stateful object for tracking what happens:
  class SubscriptionPayload
    attr_reader :str

    def initialize
      @str = "Update"
      @counter = 0
    end

    def int
      @counter += 1
    end
  end
end

class ClassBasedInMemoryBackend < InMemoryBackend
  class Payload < GraphQL::Schema::Object
    field :str, String, null: false
    field :int, Integer, null: false do
      def visible?(context)
        !context[:other_int]
      end
    end

    field :int, Integer, null: false, resolver_method: :other_int do
      def visible?(context)
        !!context[:other_int]
      end
    end

    def other_int
      1000 + object.int
    end
  end

  class PayloadType < GraphQL::Schema::Enum
    graphql_name "PayloadType"
    # Arbitrary "kinds" of payloads which may be
    # subscribed to separately
    value "ONE"
    value "TWO"
  end

  class StreamInput < GraphQL::Schema::InputObject
    argument :user_id, ID, camelize: false
    argument :payload_type, PayloadType, required: false, default_value: "ONE", prepare: ->(e, ctx) { e ? e.downcase : e }
  end

  class EventSubscription < GraphQL::Schema::Subscription
    argument :user_id, ID, as: :user
    argument :payload_type, PayloadType, required: false, default_value: "ONE", prepare: ->(e, ctx) { e ? e.downcase : e }
    field :payload, Payload
  end

  class FilteredStream < GraphQL::Schema::Subscription
    subscription_scope :segment
    argument :channel, Integer, required: false

    field :message, String, null: false

    def update(channel: nil)
      if channel && object.channel != channel
        NO_UPDATE
      else
        super
      end
    end

    def self.topic_for(arguments:, field:, scope:)
      "#{field.graphql_name}:#{scope}"
    end
  end

  class SharedEvent < GraphQL::Schema::Subscription
    subscription_scope :shared_stream

    field :ok, Boolean

    def self.topic_for(arguments:, field:, scope:)
      scope.to_s
    end
  end

  class OtherSharedEvent < SharedEvent
  end

  class Subscription < GraphQL::Schema::Object
    field :payload, Payload, null: false do
      argument :id, ID
    end

    field :event, Payload do
      argument :stream, StreamInput, required: false
    end

    field :event_subscription, subscription: EventSubscription

    field :my_event, Payload, subscription_scope: :me do
      argument :payload_type, PayloadType, required: false
    end

    field :failed_event, Payload, null: false  do
      argument :id, ID
    end

    def failed_event(id:)
      raise GraphQL::ExecutionError.new("unauthorized")
    end

    field :filtered_stream, subscription: FilteredStream

    field :hidden_event, Payload do
      def visible?(context)
        !!context[:hidden_event]
      end
    end

    field :shared_event, subscription: SharedEvent
    field :other_shared_event, subscription: OtherSharedEvent
  end

  class Query < GraphQL::Schema::Object
    field :dummy, Integer
  end

  class Schema < GraphQL::Schema
    query { Query }
    subscription { Subscription }
    use InMemoryBackend::Subscriptions, extra: 123
    max_complexity(InMemoryBackend::MAX_COMPLEXITY)
    use GraphQL::Schema::Warden if ADD_WARDEN
  end
end

class FromDefinitionInMemoryBackend < InMemoryBackend
  SchemaDefinition = <<-GRAPHQL
  type Subscription {
    payload(id: ID!): Payload!
    event(stream: StreamInput): Payload
    eventSubscription(userId: ID, payloadType: PayloadType = ONE): EventSubscriptionPayload
    myEvent(payloadType: PayloadType): Payload
    failedEvent(id: ID!): Payload!
  }

  type Payload {
    str: String!
    int: Int!
  }

  type EventSubscriptionPayload {
    payload: Payload
  }

  input StreamInput {
    user_id: ID!
    payloadType: PayloadType = ONE
  }

  # Arbitrary "kinds" of payloads which may be
  # subscribed to separately
  enum PayloadType {
    ONE
    TWO
  }

  type Query {
    dummy: Int
  }
  GRAPHQL


  DEFAULT_SUBSCRIPTION_RESOLVE = ->(o,a,c) {
    if c.query.subscription_update?
      o
    else
      c.skip
    end
  }

  Resolvers = {
    "Subscription" => {
      "payload" => DEFAULT_SUBSCRIPTION_RESOLVE,
      "myEvent" => DEFAULT_SUBSCRIPTION_RESOLVE,
      "event" => DEFAULT_SUBSCRIPTION_RESOLVE,
      "eventSubscription" => ->(o,a,c) { nil },
      "failedEvent" => ->(o,a,c) { raise GraphQL::ExecutionError.new("unauthorized") },
    },
  }
  Schema = GraphQL::Schema.from_definition(SchemaDefinition, default_resolve: Resolvers, using: {InMemoryBackend::Subscriptions => { extra: 123 }})
  Schema.max_complexity(MAX_COMPLEXITY)
  # TODO don't hack this (no way to add metadata from IDL parser right now)
  Schema.get_field("Subscription", "myEvent").subscription_scope = :me
end

class ToParamUser
  def initialize(id)
    @id = id
  end

  def to_param
    @id
  end
end

describe GraphQL::Subscriptions do
  [ClassBasedInMemoryBackend, FromDefinitionInMemoryBackend].each do |in_memory_backend_class|
    describe "using #{in_memory_backend_class}" do
      before do
        schema.subscriptions.reset
      end
      let(:root_object) {
        OpenStruct.new(
          payload: in_memory_backend_class::SubscriptionPayload.new,
          )
      }

      let(:schema) { in_memory_backend_class::Schema }
      let(:implementation) { schema.subscriptions }
      let(:deliveries) { implementation.deliveries }
      let(:subscriptions_by_topic) {
        implementation.events.each_with_object({}) do |(k, v), obj|
          obj[k] = v.size
        end
      }

      describe "pushing updates" do
        it "sends updated data" do
          query_str = <<-GRAPHQL
        subscription ($id: ID!){
          firstPayload: payload(id: $id) { str, int }
          otherPayload: payload(id: "900") { int }
        }
          GRAPHQL

          # Initial subscriptions
          res_1 = schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)
          res_2 = schema.execute(query_str, context: { socket: "2" }, variables: { "id" => "200" }, root_value: root_object)

          empty_response = {}

          # Initial response is nil, no broadcasts yet
          assert_equal(empty_response, res_1["data"])
          assert_equal(empty_response, res_2["data"])
          assert_equal [], deliveries["1"]
          assert_equal [], deliveries["2"]

          # Application stuff happens.
          # The application signals graphql via `subscriptions.trigger`:
          schema.subscriptions.trigger(:payload, {"id" => "100"}, root_object.payload)
          schema.subscriptions.trigger("payload", {"id" => "200"}, root_object.payload)
          # Symbols are OK too
          schema.subscriptions.trigger(:payload, {:id => "100"}, root_object.payload)
          schema.subscriptions.trigger("payload", {"id" => "300"}, nil)

          # Let's see what GraphQL sent over the wire:
          assert_equal({"str" => "Update", "int" => 1}, deliveries["1"][0]["data"]["firstPayload"])
          assert_equal({"str" => "Update", "int" => 2}, deliveries["2"][0]["data"]["firstPayload"])
          assert_equal({"str" => "Update", "int" => 3}, deliveries["1"][1]["data"]["firstPayload"])
        end
      end

      it "works with the introspection query" do
        res = schema.execute("{ __schema { subscriptionType { name } } }")
        assert_equal "Subscription", res["data"]["__schema"]["subscriptionType"]["name"]
      end

      if in_memory_backend_class != FromDefinitionInMemoryBackend # No way to specify this when using IDL
        it "supports filtering in the subscription class" do
          query_str = "subscription($channel: Int) { filteredStream(channel: $channel) { message } }"

          # Unfiltered:
          schema.execute(query_str, context: { socket: "1", segment: "A" }, variables: {})
          # Filtered:
          schema.execute(query_str, context: { socket: "2", segment: "A" }, variables: { channel: 1 })
          schema.execute(query_str, context: { socket: "3", segment: "A" }, variables: { channel: 2 })

          # Another Subscription scope:
          schema.execute(query_str, context: { socket: "4", segment: "B" }, variables: {})
          schema.execute(query_str, context: { socket: "5", segment: "B" }, variables: { channel: 1 })

          schema.subscriptions.trigger(:filtered_stream, {}, OpenStruct.new(channel: 1, message: "Message 1"), scope: "A")
          schema.subscriptions.trigger(:filtered_stream, {}, OpenStruct.new(channel: 2, message: "Message 2"), scope: "A")
          schema.subscriptions.trigger(:filtered_stream, {}, OpenStruct.new(channel: 3, message: "Message 3"), scope: "A")

          # Unfiltered, received all updates:
          assert_equal 3, deliveries["1"].size
          # Only received updates that matched `channel`:
          assert_equal 1, deliveries["2"].size
          assert_equal 1, deliveries["3"].size
          # Different segment, no updates:
          assert_equal 0, deliveries["4"].size
          assert_equal 0, deliveries["5"].size

          schema.subscriptions.trigger(:filtered_stream, {}, OpenStruct.new(channel: 1, message: "Message 4"), scope: "B")
          schema.subscriptions.trigger(:filtered_stream, {}, OpenStruct.new(channel: 2, message: "Message 5"), scope: "B")

          # These should be unchanged because the later triggers had a different scope value:
          assert_equal 3, deliveries["1"].size
          assert_equal 1, deliveries["2"].size
          assert_equal 1, deliveries["3"].size
          # These received updates from the second set of triggers:
          assert_equal 2, deliveries["4"].size
          assert_equal 1, deliveries["5"].size
        end

        it "runs visibility checks when calling .trigger" do
          query_str = "subscription { hiddenEvent { int } }"
          res_1 = schema.execute(query_str, context: { socket: "1", hidden_event: true }, root_value: root_object)
          assert_equal({}, res_1["data"])

          schema.subscriptions.trigger(:hidden_event, {}, root_object.payload, context: { hidden_event: true })
          assert_equal({"hiddenEvent" => { "int" => 1 }}, deliveries["1"][0]["data"])

          err = assert_raises GraphQL::Subscriptions::InvalidTriggerError do
            schema.subscriptions.trigger(:hidden_event, {}, root_object.payload)
          end
          assert_equal "No subscription matching trigger: hidden_event (looked for Subscription.hiddenEvent)", err.message
        end
      end

      it "sends updated data for multifield subscriptions" do
        query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
          event { int }
        }
        GRAPHQL

        # Initial subscriptions
        res = schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)
        empty_response = {}

        # Initial response is nil, no broadcasts yet
        assert_equal(empty_response, res["data"])
        assert_equal [], deliveries["1"]

        # Application stuff happens.
        # The application signals graphql via `subscriptions.trigger`:
        schema.subscriptions.trigger(:payload, {"id" => "100"}, root_object.payload)

        # Let's see what GraphQL sent over the wire:
        assert_equal({"str" => "Update", "int" => 1}, deliveries["1"][0]["data"]["payload"])
        assert_nil(deliveries["1"][0]["data"]["event"])

        # Trigger another field subscription
        schema.subscriptions.trigger(:event, {}, OpenStruct.new(int: 1))

        # Now we should get result for another field
        assert_nil(deliveries["1"][1]["data"]["payload"])
        assert_equal({"int" => 1}, deliveries["1"][1]["data"]["event"])
      end

      describe "passing a document into #execute" do
        it "sends the updated data" do
          query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
        }
          GRAPHQL

          document = GraphQL.parse(query_str)

          # Initial subscriptions
          response = schema.execute(nil, document: document, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)

          empty_response = {}

          # Initial response is empty, no broadcasts yet
          assert_equal(empty_response, response["data"])
          assert_equal [], deliveries["1"]

          # Application stuff happens.
          # The application signals graphql via `subscriptions.trigger`:
          schema.subscriptions.trigger(:payload, {"id" => "100"}, root_object.payload)
          # Symbols are OK too
          schema.subscriptions.trigger(:payload, {:id => "100"}, root_object.payload)
          schema.subscriptions.trigger("payload", {"id" => "300"}, nil)

          # Let's see what GraphQL sent over the wire:
          assert_equal({"str" => "Update", "int" => 1}, deliveries["1"][0]["data"]["payload"])
          assert_equal({"str" => "Update", "int" => 2}, deliveries["1"][1]["data"]["payload"])
        end
      end

      describe "subscribing" do
        it "doesn't call the subscriptions for invalid queries" do
          query_str = <<-GRAPHQL
        subscription ($id: ID){
          payload(id: $id) { str, int }
        }
          GRAPHQL

          res = schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "100" }, root_value: root_object)
          assert_equal true, res.key?("errors")
          assert_equal 0, implementation.events.size
          assert_equal 0, implementation.queries.size
        end
      end

      describe "trigger" do
        let(:error_payload_class) {
          Class.new {
            def int
              raise "Boom!"
            end

            def str
              raise GraphQL::ExecutionError.new("This is handled")
            end
          }
        }

        it "uses the provided queue" do
          query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
        }
          GRAPHQL

          schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "8" }, root_value: root_object)
          schema.subscriptions.trigger("payload", { "id" => "8"}, root_object.payload)
          assert_equal ["1"], implementation.pushes
        end

        it "pushes errors" do
          query_str = <<-GRAPHQL
        subscription ($id: ID!){
          payload(id: $id) { str, int }
        }
          GRAPHQL

          schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "8" }, root_value: root_object)
          schema.subscriptions.trigger("payload", { "id" => "8"}, OpenStruct.new(str: nil, int: nil))
          delivery = deliveries["1"].first
          assert_nil delivery.fetch("data")
          assert_equal 1, delivery["errors"].length
        end

        it "unsubscribes when `read_subscription` returns nil" do
          query_str = <<-GRAPHQL
            subscription ($id: ID!){
              payload(id: $id) { str, int }
            }
          GRAPHQL

          schema.execute(query_str, context: { socket: "1" }, variables: { "id" => "8" }, root_value: root_object)
          assert_equal 1, implementation.events.size
          sub_id = implementation.queries.keys.first
          # Mess with the private storage so that `read_subscription` will be nil
          implementation.queries.delete(sub_id)
          assert_equal 1, implementation.events.size
          assert_nil implementation.read_subscription(sub_id)

          # The trigger should clean up the lingering subscription:
          schema.subscriptions.trigger("payload", { "id" => "8"}, OpenStruct.new(str: nil, int: nil))
          assert_equal 0, implementation.events.size
          assert_equal 0, implementation.queries.size
        end

        it "coerces args" do
          query_str = <<-GRAPHQL
            subscription($type: PayloadType) {
              e1: event(stream: { user_id: "3", payloadType: $type }) { int }
            }
          GRAPHQL

          # Subscribe with explicit `TYPE`
          schema.execute(query_str, context: { socket: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
          # Subscribe with default `TYPE`
          schema.execute(query_str, context: { socket: "2" }, root_value: root_object)
          # Subscribe with non-matching `TYPE`
          schema.execute(query_str, context: { socket: "3" }, variables: { "type" => "TWO" }, root_value: root_object)
          # Subscribe with explicit null
          schema.execute(query_str, context: { socket: "4" }, variables: { "type" => nil }, root_value: root_object)

          # The class-based schema has a "prepare" behavior, so it expects these downcased values in `.trigger`
          if schema == ClassBasedInMemoryBackend::Schema
            one = "one"
            two = "two"
          else
            one = "ONE"
            two = "TWO"
          end

          # Trigger the subscription with coerceable args, different orders:
          schema.subscriptions.trigger("event", { "stream" => {"user_id" => 3, "payloadType" => one} }, OpenStruct.new(str: "", int: 1))
          schema.subscriptions.trigger("event", { "stream" => {"payloadType" => one, "user_id" => "3"} }, OpenStruct.new(str: "", int: 2))
          # This is a non-trigger
          schema.subscriptions.trigger("event", { "stream" => {"user_id" => "3", "payloadType" => two} }, OpenStruct.new(str: "", int: 3))
          # These get default value of ONE (underscored / symbols are ok)
          schema.subscriptions.trigger("event", { stream: { user_id: "3"} }, OpenStruct.new(str: "", int: 4))
          # Trigger with null updates subscriptions to null
          schema.subscriptions.trigger("event", { "stream" => {"user_id" => 3, "payloadType" => nil} }, OpenStruct.new(str: "", int: 5))

          assert_equal [1,2,4], deliveries["1"].map { |d| d["data"]["e1"]["int"] }

          # Same as socket_1
          assert_equal [1,2,4], deliveries["2"].map { |d| d["data"]["e1"]["int"] }

          # Received the "non-trigger"
          assert_equal [3], deliveries["3"].map { |d| d["data"]["e1"]["int"] }

          # Received the trigger with null
          assert_equal [5], deliveries["4"].map { |d| d["data"]["e1"]["int"] }
        end

        it "allows context-scoped subscriptions" do
          query_str = <<-GRAPHQL
            subscription($type: PayloadType) {
              myEvent(payloadType: $type) { int }
            }
          GRAPHQL

          # Subscriptions for user 1
          schema.execute(query_str, context: { socket: "1", me: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
          schema.execute(query_str, context: { socket: "2", me: "1" }, variables: { "type" => "TWO" }, root_value: root_object)
          # Subscription for user 2
          schema.execute(query_str, context: { socket: "3", me: "2" }, variables: { "type" => "ONE" }, root_value: root_object)

          schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, OpenStruct.new(str: "", int: 1), scope: "1")
          schema.subscriptions.trigger("myEvent", { "payloadType" => "TWO" }, OpenStruct.new(str: "", int: 2), scope: "1")
          schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, OpenStruct.new(str: "", int: 3), scope: "2")

          # Delivered to user 1
          assert_equal [1], deliveries["1"].map { |d| d["data"]["myEvent"]["int"] }
          assert_equal [2], deliveries["2"].map { |d| d["data"]["myEvent"]["int"] }
          # Delivered to user 2
          assert_equal [3], deliveries["3"].map { |d| d["data"]["myEvent"]["int"] }
        end

        if defined?(GlobalID)
          it "allows complex object subscription scopes" do
            query_str = <<-GRAPHQL
              subscription($type: PayloadType) {
                myEvent(payloadType: $type) { int }
              }
            GRAPHQL

            # Global ID Backed User
            schema.execute(query_str, context: { socket: "1", me: GlobalIDUser.new(1) }, variables: { "type" => "ONE" }, root_value: root_object)
            schema.execute(query_str, context: { socket: "2", me: GlobalIDUser.new(1) }, variables: { "type" => "TWO" }, root_value: root_object)
            # ToParam Backed User
            schema.execute(query_str, context: { socket: "3", me: ToParamUser.new(2) }, variables: { "type" => "ONE" }, root_value: root_object)
            # Array of Objects
            schema.execute(query_str, context: { socket: "4", me: [GlobalIDUser.new(4), ToParamUser.new(5)] }, variables: { "type" => "ONE" }, root_value: root_object)

            schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, OpenStruct.new(str: "", int: 1), scope: GlobalIDUser.new(1))
            schema.subscriptions.trigger("myEvent", { "payloadType" => "TWO" }, OpenStruct.new(str: "", int: 2), scope: GlobalIDUser.new(1))
            schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, OpenStruct.new(str: "", int: 3), scope: ToParamUser.new(2))
            schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, OpenStruct.new(str: "", int: 4), scope: [GlobalIDUser.new(4), ToParamUser.new(5)])

            # Delivered to GlobalIDUser
            assert_equal [1], deliveries["1"].map { |d| d["data"]["myEvent"]["int"] }
            assert_equal [2], deliveries["2"].map { |d| d["data"]["myEvent"]["int"] }
            # Delivered to ToParamUser
            assert_equal [3], deliveries["3"].map { |d| d["data"]["myEvent"]["int"] }
            # Delivered to Array of GlobalIDUser and ToParamUser
            assert_equal [4], deliveries["4"].map { |d| d["data"]["myEvent"]["int"] }
          end
        end

        describe "building topic string when `prepare:` is given" do
          it "doesn't apply with a Subscription class" do
            query_str = <<-GRAPHQL
              subscription($type: PayloadType = TWO) {
                eventSubscription(userId: "3", payloadType: $type) { payload { int } }
              }
            GRAPHQL

            query_str_2 = <<-GRAPHQL
              subscription {
                eventSubscription(userId: "4", payloadType: ONE) { payload { int } }
              }
            GRAPHQL

            query_str_3 = <<-GRAPHQL
              subscription {
                eventSubscription(userId: "4") { payload { int } }
              }
            GRAPHQL
            # Value from variable
            schema.execute(query_str, context: { socket: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
            # Default value for variable
            schema.execute(query_str, context: { socket: "1" }, root_value: root_object)
            # Query string literal value
            schema.execute(query_str_2, context: { socket: "1" }, root_value: root_object)
            # Schema default value
            schema.execute(query_str_3, context: { socket: "1" }, root_value: root_object)

            # There's no way to add `prepare:` when using SDL, so only the Ruby-defined schema has it
            expected_sub_count = if schema == ClassBasedInMemoryBackend::Schema
              {
                ":eventSubscription:payloadType:one:userId:3" => 1,
                ":eventSubscription:payloadType:one:userId:4" => 2,
                ":eventSubscription:payloadType:two:userId:3" => 1,
              }
            else
              {
                ":eventSubscription:payloadType:ONE:userId:3" => 1,
                ":eventSubscription:payloadType:ONE:userId:4" => 2,
                ":eventSubscription:payloadType:TWO:userId:3" => 1,
              }
            end
            assert_equal expected_sub_count, subscriptions_by_topic

            schema.subscriptions.trigger(:event_subscription, { user_id: 3 }, {})
            assert_equal 1, deliveries["1"].size
          end

          it "doesn't apply for plain fields" do
            query_str = <<-GRAPHQL
              subscription($type: PayloadType = TWO) {
                e1: event(stream: { user_id: "3", payloadType: $type }) { int }
              }
            GRAPHQL

            query_str_2 = <<-GRAPHQL
              subscription {
                event(stream: { user_id: "4", payloadType: ONE}) { int }
              }
            GRAPHQL

            query_str_3 = <<-GRAPHQL
              subscription {
                event(stream: { user_id: "4" }) { int }
              }
            GRAPHQL
            # Value from variable
            schema.execute(query_str, context: { socket: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
            # Default value for variable
            schema.execute(query_str, context: { socket: "1" }, root_value: root_object)
            # Query string literal value
            schema.execute(query_str_2, context: { socket: "1" }, root_value: root_object)
            # Schema default value
            schema.execute(query_str_3, context: { socket: "1" }, root_value: root_object)


            # There's no way to add `prepare:` when using SDL, so only the Ruby-defined schema has it
            expected_sub_count = if schema == ClassBasedInMemoryBackend::Schema
              {
                ":event:stream:payloadType:one:user_id:3" => 1,
                ":event:stream:payloadType:two:user_id:3" => 1,
                ":event:stream:payloadType:one:user_id:4" => 2,
              }
            else
              {
                ":event:stream:payloadType:ONE:user_id:3" => 1,
                ":event:stream:payloadType:TWO:user_id:3" => 1,
                ":event:stream:payloadType:ONE:user_id:4" => 2,
              }
            end
            assert_equal expected_sub_count, subscriptions_by_topic
          end
        end

        describe "errors" do
          it "avoid subscription on resolver error" do
            res = schema.execute(<<-GRAPHQL, context: { socket: "1" }, variables: { "id" => "100" })
          subscription ($id: ID!){
            failedEvent(id: $id) { str, int }
          }
            GRAPHQL
            assert_nil res["data"]
            assert_equal "unauthorized", res["errors"][0]["message"]

            assert_equal 0, subscriptions_by_topic.size
          end

          it "lets unhandled errors crash" do
            query_str = <<-GRAPHQL
          subscription($type: PayloadType) {
            myEvent(payloadType: $type) { int }
          }
            GRAPHQL

            schema.execute(query_str, context: { socket: "1", me: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
            err = assert_raises(RuntimeError) {
              schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, error_payload_class.new, scope: "1")
            }
            assert_equal "Boom!", err.message
          end
        end

        it "sends query errors to the subscriptions" do
          query_str = <<-GRAPHQL
            subscription($type: PayloadType) {
              myEvent(payloadType: $type) { str }
            }
          GRAPHQL

          schema.execute(query_str, context: { socket: "1", me: "1" }, variables: { "type" => "ONE" }, root_value: root_object)
          schema.subscriptions.trigger("myEvent", { "payloadType" => "ONE" }, error_payload_class.new, scope: "1")
          res = deliveries["1"].first
          assert_equal "This is handled", res["errors"][0]["message"]
        end
      end

      describe "implementation" do
        it "is initialized with keywords" do
          assert_equal 123, schema.subscriptions.extra
        end
      end

      describe "#build_id" do
        it "returns a unique ID string" do
          assert_instance_of String, schema.subscriptions.build_id
          refute_equal schema.subscriptions.build_id, schema.subscriptions.build_id
        end
      end

      describe ".trigger" do
        it "raises when event name is not found" do
          err = assert_raises(GraphQL::Subscriptions::InvalidTriggerError) do
            schema.subscriptions.trigger(:nonsense_field, {}, nil)
          end

          assert_includes err.message, "trigger: nonsense_field"
          assert_includes err.message, "Subscription.nonsenseField"
        end

        it "raises when argument is not found" do
          err = assert_raises(GraphQL::Subscriptions::InvalidTriggerError) do
            schema.subscriptions.trigger(:event, { scream: {"user_id" => "😱"} }, nil)
          end

          assert_includes err.message, "arguments: scream"
          assert_includes err.message, "arguments of Subscription.event"

          err = assert_raises(GraphQL::Subscriptions::InvalidTriggerError) do
            schema.subscriptions.trigger(:event, { stream: { user_id_number: "😱"} }, nil)
          end

          assert_includes err.message, "arguments: user_id_number"
          assert_includes err.message, "arguments of StreamInput"
        end
      end

      describe "max_complexity" do
        it "rejects subscriptions with errors" do
          query_str = <<-GRAPHQL
            subscription($type: PayloadType) {
              myEvent(payloadType: $type) {
                s1: str
                s2: str
                s3: str
                s4: str
                s5: str
                s6: str
              }
            }
          GRAPHQL

          res = schema.execute(query_str, context: { socket: "1"})
          errs = ["Query has complexity of 7, which exceeds max complexity of 5"]
          assert_equal errs, res["errors"].map { |e| e["message"] }
          assert_equal 0, implementation.events.size
          assert_equal 0, implementation.queries.size
        end
      end
    end
  end

  it "can share topics" do
    schema = ClassBasedInMemoryBackend::Schema
    schema.subscriptions.reset
    schema.execute("subscription { sharedEvent { ok } }", context: { shared_stream: "stream-1", socket: "1" } )
    schema.execute("subscription { otherSharedEvent { ok __typename } }", context: { shared_stream: "stream-1", socket: "2" } )

    schema.subscriptions.trigger(:shared_event, {}, OpenStruct.new(ok: true), scope: "stream-1")
    schema.subscriptions.trigger(:other_shared_event, {}, OpenStruct.new(ok: false), scope: "stream-1")

    pushed_results = schema.subscriptions.deliveries.map do |socket, results|
      [socket, results.map { |r| r["data"] }]
    end

    expected_results = [
      ["1", [{ "sharedEvent" => { "ok" => true } }, { "sharedEvent" => { "ok" => false } }]],
      ["2", [{ "otherSharedEvent" => {"ok" => true, "__typename" => "OtherSharedEventPayload" } }, { "otherSharedEvent" => { "ok" => false, "__typename" => "OtherSharedEventPayload" } }]]
    ]
    assert_equal expected_results, pushed_results
  end

  describe "broadcast: true" do
    let(:schema) { BroadcastTrueSchema }

    before do
      BroadcastTrueSchema::COUNTERS.clear
    end

    class BroadcastTrueSchema < GraphQL::Schema
      COUNTERS = Hash.new(0)

      class Subscription < GraphQL::Schema::Object
        class BroadcastableCounter < GraphQL::Schema::Subscription
          field :value, Integer, null: false

          def update
            {
              value: COUNTERS[:broadcastable] += 1
            }
          end
        end

        class IsolatedCounter < GraphQL::Schema::Subscription
          broadcastable(false)
          field :value, Integer, null: false

          def update
            {
              value: COUNTERS[:isolated] += 1
            }
          end
        end

        field :broadcastable_counter, subscription: BroadcastableCounter
        field :isolated_counter, subscription: IsolatedCounter
      end

      class Query < GraphQL::Schema::Object
        field :int, Integer, null: false
      end

      query(Query)
      subscription(Subscription)
      use InMemoryBackend::Subscriptions, extra: nil,
        broadcast: true, default_broadcastable: true
    end

    def exec_query(query_str, **options)
      BroadcastTrueSchema.execute(query_str, **options)
    end

    it "broadcasts when possible" do
      assert_equal false, BroadcastTrueSchema.get_field("Subscription", "isolatedCounter").broadcastable?

      exec_query("subscription { counter: broadcastableCounter { value } }", context: { socket: "1" })
      exec_query("subscription { counter: broadcastableCounter { value } }", context: { socket: "2" })
      exec_query("subscription { counter: broadcastableCounter { value __typename } }", context: { socket: "3" })

      exec_query("subscription { counter: isolatedCounter { value } }", context: { socket: "1" })
      exec_query("subscription { counter: isolatedCounter { value } }", context: { socket: "2" })
      exec_query("subscription { counter: isolatedCounter { value } }", context: { socket: "3" })

      schema.subscriptions.trigger(:broadcastable_counter, {}, {})
      schema.subscriptions.trigger(:isolated_counter, {}, {})

      expected_counters = { broadcastable: 2, isolated: 3 }
      assert_equal expected_counters, BroadcastTrueSchema::COUNTERS

      delivered_values = schema.subscriptions.deliveries.map do |channel, results|
        results.map { |r| r["data"]["counter"]["value"] }
      end

      # Socket 1 received 1, 1
      # Socket 2 received 1, 2 (same broadcast as Socket 1)
      # Socket 3 received 2, 3
      expected_values = [[1,1], [1,2], [2,3]]
      assert_equal expected_values, delivered_values
    end
  end

  class SkipUpdateValidationSchema < GraphQL::Schema
    COUNTERS = Hash.new(0)
    class ValidationDetectionTracer
      def self.trace(event, data)
        if event == "validate"
          COUNTERS["validate_#{data[:validate]}"] += 1
          data[:query].context[:was_validated] = data[:validate]
        end
        yield
      end
    end

    class Subscription < GraphQL::Schema::Object
      class Counter < GraphQL::Schema::Subscription
        argument :id, ID
        field :value, Integer, null: false

        def update(id:)
          {
            value: COUNTERS["counter_#{id}"] += 1
          }
        end
      end

      field :counter, subscription: Counter
    end
    subscription(Subscription)
    tracer(ValidationDetectionTracer)
    use InMemoryBackend::Subscriptions, extra: nil, validate_update: false
  end

  class SometimesSkipUpdateValidationSchema < GraphQL::Schema
    COUNTERS = SkipUpdateValidationSchema::COUNTERS
    class SometimesSkipSubscriptions < InMemoryBackend::Subscriptions
      def validate_update?(context:, **_rest)
        !!context[:validate_update]
      end
    end

    subscription(SkipUpdateValidationSchema::Subscription)
    tracer(SkipUpdateValidationSchema::ValidationDetectionTracer)
    use(SometimesSkipSubscriptions, extra: nil)
  end

  describe "Skipping validation on updates" do
    before do
      schema::COUNTERS.clear
    end

    let(:schema) { SkipUpdateValidationSchema }
    it "Skips validation when configured" do
      res = schema.execute("subscription { counter(id: \"1\") { value } }", context: { socket: "1" })
      assert res.context[:was_validated]
      assert_equal({"validate_true" => 1}, schema::COUNTERS)
      schema.subscriptions.trigger(:counter, {id: "1"}, {})
      assert_equal({"validate_true" => 1, "validate_false" => 1, "counter_1" => 1}, schema::COUNTERS)
    end

    describe "when the method is overridden" do
      let(:schema) { SometimesSkipUpdateValidationSchema }
      it "calls `validate_update?`" do
        schema.execute("subscription { counter(id: \"3\") { value } }", context: { socket: "2" })
        schema.execute("subscription { counter(id: \"3\") { value } }", context: { socket: "3", validate_update: true })
        assert_equal({"validate_true" => 2}, schema::COUNTERS)
        schema.subscriptions.trigger(:counter, {id: "3"}, {})
        assert_equal({"validate_true" => 3, "validate_false" => 1, "counter_3" => 2}, schema::COUNTERS)
      end
    end
  end

  describe ".trigger" do
    let(:schema) {
      Class.new(ClassBasedInMemoryBackend::Schema) do
        def self.parse_error(err, context)
          raise err
        end

        use InMemoryBackend::Subscriptions, extra: 123
      end
    }

    it "Doesn't create a ParseError under the hood when triggering" do
      res = schema.subscriptions.trigger("payload", { "id" => "8"}, OpenStruct.new(str: nil, int: nil))
      assert res
    end
  end

  describe "Triggering with custom enum values" do
    module SubscriptionEnum
      class InMemorySubscriptions < GraphQL::Subscriptions
        attr_reader :write_subscription_events, :execute_all_events

        def initialize(...)
          super
          reset
        end

        def write_subscription(_query, events)
          @write_subscription_events.concat(events)
        end

        def execute_all(event, _object)
          @execute_all_events.push(event)
        end

        def reset
          @write_subscription_events = []
          @execute_all_events = []
        end
      end

      class MyEnumType < GraphQL::Schema::Enum
        value "ONE", value: "one"
        value "TWO", value: "two"
      end

      class MySubscription < GraphQL::Schema::Subscription
        argument :my_enum, MyEnumType
        field :my_enum, MyEnumType
      end

      class SubscriptionType < GraphQL::Schema::Object
        field :my_subscription, resolver: MySubscription
      end

      class Schema < GraphQL::Schema
        subscription SubscriptionType
        use InMemorySubscriptions
      end
    end

    let(:schema) { SubscriptionEnum::Schema }
    let(:implementation) { schema.subscriptions }
    let(:write_subscription_events) { implementation.write_subscription_events }
    let(:execute_all_events) { implementation.execute_all_events }

    it "builds matching event names" do
      query_str = <<-GRAPHQL
        subscription ($myEnum: MyEnum!) {
          mySubscription (myEnum: $myEnum) {
            myEnum
          }
        }
      GRAPHQL

      schema.execute(query_str, variables: { "myEnum" => "ONE" })

      schema.subscriptions.trigger(:mySubscription, { "myEnum" => "ONE" }, nil)

      assert_equal(":mySubscription:myEnum:one", write_subscription_events[0].topic)
      assert_equal(":mySubscription:myEnum:one", execute_all_events[0].topic)
    end
  end

  describe "Triggering with nested input object" do
    module SubscriptionNestedInput
      class InMemoryBackend < GraphQL::Subscriptions
        attr_reader :write_subscription_events, :execute_all_events

        def initialize(...)
          super
          reset
        end

        def write_subscription(_query, events)
          @write_subscription_events.concat(events)
        end

        def execute_all(event, _object)
          @execute_all_events.push(event)
        end

        def reset
          @write_subscription_events = []
          @execute_all_events = []
        end
      end

      class InnerInput < GraphQL::Schema::InputObject
        argument :first_name, String, required: false
        argument :last_name, String, required: false
      end

      class OuterInput < GraphQL::Schema::InputObject
        argument :inner_input, [InnerInput, { null: true }], required: false
      end

      class MySubscription < GraphQL::Schema::Subscription
        argument :input, OuterInput, required: false
        field :full_name, String
      end

      class SubscriptionType < GraphQL::Schema::Object
        field :my_subscription, resolver: MySubscription
      end

      class Schema < GraphQL::Schema
        subscription SubscriptionType
        use InMemoryBackend
      end
    end

    let(:schema) { SubscriptionNestedInput::Schema }
    let(:implementation) { schema.subscriptions }
    let(:write_subscription_events) { implementation.write_subscription_events }
    let(:execute_all_events) { implementation.execute_all_events }

    before do
      write_subscription_events.clear
      execute_all_events.clear
    end

    it 'correctly generates subscription topics when triggering with nil inner input' do
      query_str = <<-GRAPHQL
        subscription ($input: OuterInput) {
          mySubscription (input: $input) {
            fullName
          }
        }
      GRAPHQL

      schema.execute(query_str, variables: { 'input' => { 'innerInput' => nil } })

      schema.subscriptions.trigger(:mySubscription, { 'input' => { 'innerInput' => nil } }, nil)

      assert_equal(':mySubscription:input:innerInput:', write_subscription_events[0].topic)
      assert_equal(':mySubscription:input:innerInput:', execute_all_events[0].topic)
    end

    it 'correctly generates subscription topics when triggering with nil as input value' do
      query_str = <<-GRAPHQL
        subscription ($input: OuterInput) {
          mySubscription (input: $input) {
            fullName
          }
        }
      GRAPHQL

      schema.execute(query_str, variables: { 'input' => nil })

      schema.subscriptions.trigger(:mySubscription, { 'input' => nil }, nil)

      assert_equal(':mySubscription:input:', write_subscription_events[0].topic)
      assert_equal(':mySubscription:input:', execute_all_events[0].topic)
    end
  end
end
