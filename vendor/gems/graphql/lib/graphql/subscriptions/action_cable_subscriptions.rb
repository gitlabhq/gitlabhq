# frozen_string_literal: true
module GraphQL
  class Subscriptions
    # A subscriptions implementation that sends data
    # as ActionCable broadcastings.
    #
    # Some things to keep in mind:
    #
    # - No queueing system; ActiveJob should be added
    # - Take care to reload context when re-delivering the subscription. (see {Query#subscription_update?})
    # - Avoid the async ActionCable adapter and use the redis or PostgreSQL adapters instead. Otherwise calling #trigger won't work from background jobs or the Rails console.
    #
    # @example Adding ActionCableSubscriptions to your schema
    #   class MySchema < GraphQL::Schema
    #     # ...
    #     use GraphQL::Subscriptions::ActionCableSubscriptions
    #   end
    #
    # @example Implementing a channel for GraphQL Subscriptions
    #   class GraphqlChannel < ApplicationCable::Channel
    #     def subscribed
    #       @subscription_ids = []
    #     end
    #
    #     def execute(data)
    #       query = data["query"]
    #       variables = ensure_hash(data["variables"])
    #       operation_name = data["operationName"]
    #       context = {
    #         # Re-implement whatever context methods you need
    #         # in this channel or ApplicationCable::Channel
    #         # current_user: current_user,
    #         # Make sure the channel is in the context
    #         channel: self,
    #       }
    #
    #       result = MySchema.execute(
    #         query,
    #         context: context,
    #         variables: variables,
    #         operation_name: operation_name
    #       )
    #
    #       payload = {
    #         result: result.to_h,
    #         more: result.subscription?,
    #       }
    #
    #       # Track the subscription here so we can remove it
    #       # on unsubscribe.
    #       if result.context[:subscription_id]
    #         @subscription_ids << result.context[:subscription_id]
    #       end
    #
    #       transmit(payload)
    #     end
    #
    #     def unsubscribed
    #       @subscription_ids.each { |sid|
    #         MySchema.subscriptions.delete_subscription(sid)
    #       }
    #     end
    #
    #     private
    #
    #       def ensure_hash(ambiguous_param)
    #         case ambiguous_param
    #         when String
    #           if ambiguous_param.present?
    #             ensure_hash(JSON.parse(ambiguous_param))
    #           else
    #             {}
    #           end
    #         when Hash, ActionController::Parameters
    #           ambiguous_param
    #         when nil
    #           {}
    #         else
    #           raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    #         end
    #       end
    #   end
    #
    class ActionCableSubscriptions < GraphQL::Subscriptions
      SUBSCRIPTION_PREFIX = "graphql-subscription:"
      EVENT_PREFIX = "graphql-event:"

      # @param serializer [<#dump(obj), #load(string)] Used for serializing messages before handing them to `.broadcast(msg)`
      # @param namespace [string] Used to namespace events and subscriptions (default: '')
      def initialize(serializer: Serialize, namespace: '', action_cable: ActionCable, action_cable_coder: ActiveSupport::JSON, **rest)
        # A per-process map of subscriptions to deliver.
        # This is provided by Rails, so let's use it
        @subscriptions = Concurrent::Map.new
        @events = Concurrent::Map.new do |h, k|
          h.compute_if_absent(k) do
            Concurrent::Map.new do |h2, k2|
              h2.compute_if_absent(k2) { Concurrent::Array.new }
            end
          end
        end
        @action_cable = action_cable
        @action_cable_coder = action_cable_coder
        @serializer = serializer
        @serialize_with_context = case @serializer.method(:load).arity
        when 1
          false
        when 2
          true
        else
          raise ArgumentError, "#{@serializer} must respond to `.load` accepting one or two arguments"
        end
        @transmit_ns = namespace
        super
      end

      # An event was triggered; Push the data over ActionCable.
      # Subscribers will re-evaluate locally.
      def execute_all(event, object)
        stream = stream_event_name(event)
        message = @serializer.dump(object)
        @action_cable.server.broadcast(stream, message)
      end

      # This subscription was re-evaluated.
      # Send it to the specific stream where this client was waiting.
      def deliver(subscription_id, result)
        has_more = !result.context.namespace(:subscriptions)[:final_update]
        payload = { result: result.to_h, more: has_more }
        @action_cable.server.broadcast(stream_subscription_name(subscription_id), payload)
      end

      # A query was run where these events were subscribed to.
      # Store them in memory in _this_ ActionCable frontend.
      # It will receive notifications when events come in
      # and re-evaluate the query locally.
      def write_subscription(query, events)
        unless (channel = query.context[:channel])
          raise GraphQL::Error, "This GraphQL Subscription client does not support the transport protocol expected"\
            "by the backend Subscription Server implementation (graphql-ruby ActionCableSubscriptions in this case)."\
            "Some official client implementation including Apollo (https://graphql-ruby.org/javascript_client/apollo_subscriptions.html), "\
            "Relay Modern (https://graphql-ruby.org/javascript_client/relay_subscriptions.html#actioncable)."\
            "GraphiQL via `graphiql-rails` may not work out of box (#1051)."
        end
        subscription_id = query.context[:subscription_id] ||= build_id
        stream = stream_subscription_name(subscription_id)
        channel.stream_from(stream)
        @subscriptions[subscription_id] = query
        events.each do |event|
          # Setup a new listener to run all events with this topic in this process
          setup_stream(channel, event)
          # Add this event to the list of events to be updated
          @events[event.topic][event.fingerprint] << event
        end
      end

      # Every subscribing channel is listening here, but only one of them takes any action.
      # This is so we can reuse payloads when possible, and make one payload to send to
      # all subscribers.
      #
      # But the problem is, any channel could close at any time, so each channel has to
      # be ready to take over the primary position.
      #
      # To make sure there's always one-and-only-one channel building payloads,
      # let the listener belonging to the first event on the list be
      # the one to build and publish payloads.
      #
      def setup_stream(channel, initial_event)
        topic = initial_event.topic
        event_stream = stream_event_name(initial_event)
        channel.stream_from(event_stream, coder: @action_cable_coder) do |message|
          events_by_fingerprint = @events[topic]
          object = nil
          events_by_fingerprint.each do |_fingerprint, events|
            if !events.empty? && events.first == initial_event
              # The fingerprint has told us that this response should be shared by all subscribers,
              # so just run it once, then deliver the result to every subscriber
              first_event = events.first
              first_subscription_id = first_event.context.fetch(:subscription_id)
              object ||= load_action_cable_message(message, first_event.context)
              result = execute_update(first_subscription_id, first_event, object)
              if !result.nil?
                # Having calculated the result _once_, send the same payload to all subscribers
                events.each do |event|
                  subscription_id = event.context.fetch(:subscription_id)
                  deliver(subscription_id, result)
                end
              end
            end
          end
          nil
        end
      end

      # This is called to turn an ActionCable-broadcasted string (JSON)
      # into a query-ready application object.
      # @param message [String] n ActionCable-broadcasted string (JSON)
      # @param context [GraphQL::Query::Context] the context of the first event for a given subscription fingerprint
      def load_action_cable_message(message, context)
        if @serialize_with_context
          @serializer.load(message, context)
        else
          @serializer.load(message)
        end
      end

      # Return the query from "storage" (in memory)
      def read_subscription(subscription_id)
        query = @subscriptions[subscription_id]
        if query.nil?
          # This can happen when a subscription is triggered from an unsubscribed channel,
          # see https://github.com/rmosolgo/graphql-ruby/issues/2478.
          # (This `nil` is handled by `#execute_update`)
          nil
        else
          {
            query_string: query.query_string,
            variables: query.provided_variables,
            context: query.context.to_h,
            operation_name: query.operation_name,
          }
        end
      end

      # The channel was closed, forget about it.
      def delete_subscription(subscription_id)
        query = @subscriptions.delete(subscription_id)
        # In case this came from the server, tell the client to unsubscribe:
        @action_cable.server.broadcast(stream_subscription_name(subscription_id), { more: false })
        # This can be `nil` when `.trigger` happens inside an unsubscribed ActionCable channel,
        # see https://github.com/rmosolgo/graphql-ruby/issues/2478
        if query
          events = query.context.namespace(:subscriptions)[:events]
          events.each do |event|
            ev_by_fingerprint = @events[event.topic]
            ev_for_fingerprint = ev_by_fingerprint[event.fingerprint]
            ev_for_fingerprint.delete(event)
            if ev_for_fingerprint.empty?
              ev_by_fingerprint.delete(event.fingerprint)
            end
          end
        end
      end

      private

      def stream_subscription_name(subscription_id)
        [SUBSCRIPTION_PREFIX, @transmit_ns, subscription_id].join
      end

      def stream_event_name(event)
        [EVENT_PREFIX, @transmit_ns, event.topic].join
      end
    end
  end
end
