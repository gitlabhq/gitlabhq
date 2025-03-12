# frozen_string_literal: true
class GraphqlChannel < ActionCable::Channel::Base
  class QueryType < GraphQL::Schema::Object
    field :value, Integer, null: false
    def value
      3
    end
  end

  class PayloadType < GraphQL::Schema::Object
    field :value, Integer, null: false
  end

  class CounterIncremented < GraphQL::Schema::Subscription
    def self.reset_call_count
      @@call_count = 0
    end

    reset_call_count

    field :new_value, Integer, null: false

    def update
      if object
        if object.value == "server-unsubscribe"
          unsubscribe
        elsif object.value == "server-unsubscribe-with-message"
          unsubscribe({ new_value: 9999 })
        end
      end
      result = {
        new_value: @@call_count += 1
      }
      puts "  -> CounterIncremented#update: #{result}"
      result
    end
  end

  class SubscriptionType < GraphQL::Schema::Object
    field :payload, PayloadType, null: false do
      argument :id, ID
    end

    field :counter_incremented, subscription: CounterIncremented
  end

  # Wacky behavior around the number 4
  # so we can confirm it's used by the UI
  module CustomSerializer
    def self.load(value)
      if value == "4x"
        ExamplePayload.new(400)
      else
        GraphQL::Subscriptions::Serialize.load(value)
      end
    end

    def self.dump(obj)
      if obj.is_a?(ExamplePayload) && obj.value == 4
        "4x"
      else
        GraphQL::Subscriptions::Serialize.dump(obj)
      end
    end
  end

  class GraphQLSchema < GraphQL::Schema
    query(QueryType)
    subscription(SubscriptionType)
    use GraphQL::Subscriptions::ActionCableSubscriptions,
      serializer: CustomSerializer,
      broadcast: true,
      default_broadcastable: true
  end

  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    query = data["query"]
    variables = data["variables"] || {}
    operation_name = data["operationName"]
    context = {
      # Make sure the channel is in the context
      channel: self,
    }

    puts "[GraphQLSchema.execute] #{query} || #{variables}"
    result = GraphQLSchema.execute(
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = {
      result: result.to_h,
      more: result.subscription?,
    }

    # Track the subscription here so we can remove it
    # on unsubscribe.
    if result.context[:subscription_id]
      @subscription_ids << result.context[:subscription_id]
    end
    puts "  -> [transmit(#{result.context[:subscription_id]})] #{payload.inspect}"
    transmit(payload)
  end

  def make_trigger(data)
    field = data["field"]
    args = data["arguments"]
    value = data["value"]
    value = value && ExamplePayload.new(value)
    puts "[make_trigger] #{[field, args, value]}"
    GraphQLSchema.subscriptions.trigger(field, args, value)
  end

  def unsubscribed
    @subscription_ids.each { |sid|
      puts "[delete_subscription] #{sid}"
      GraphQLSchema.subscriptions.delete_subscription(sid)
    }
  end

  # This is to make sure that GlobalID is used to load and dump this object
  class ExamplePayload
    include GlobalID::Identification
    def initialize(value)
      @value = value
    end

    def self.find(value)
      self.new(value)
    end

    attr_reader :value
    alias :id :value
  end
end
