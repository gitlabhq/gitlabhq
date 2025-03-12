# frozen_string_literal: true

require "graphql/tracing/platform_tracing"

module GraphQL
  module Tracing
    # This implementation forwards events to a notification handler (i.e.
    # ActiveSupport::Notifications or Dry::Monitor::Notifications)
    # with a `graphql` suffix.
    #
    # @see KEYS for event names
    class NotificationsTracing
      # A cache of frequently-used keys to avoid needless string allocations
      KEYS = {
        "lex" => "lex.graphql",
        "parse" => "parse.graphql",
        "validate" => "validate.graphql",
        "analyze_multiplex" => "analyze_multiplex.graphql",
        "analyze_query" => "analyze_query.graphql",
        "execute_query" => "execute_query.graphql",
        "execute_query_lazy" => "execute_query_lazy.graphql",
        "execute_field" => "execute_field.graphql",
        "execute_field_lazy" => "execute_field_lazy.graphql",
        "authorized" => "authorized.graphql",
        "authorized_lazy" => "authorized_lazy.graphql",
        "resolve_type" => "resolve_type.graphql",
        "resolve_type_lazy" => "resolve_type.graphql",
      }

      MAX_KEYS_SIZE = 100

      # Initialize a new NotificationsTracing instance
      #
      # @param [Object] notifications_engine The notifications engine to use
      def initialize(notifications_engine)
        @notifications_engine = notifications_engine
      end

      # Sends a GraphQL tracing event to the notification handler
      #
      # @example
      # . notifications_engine = Dry::Monitor::Notifications.new(:graphql)
      # . tracer = GraphQL::Tracing::NotificationsTracing.new(notifications_engine)
      # . tracer.trace("lex") { ... }
      #
      # @param [string] key The key for the event
      # @param [Hash] metadata The metadata for the event
      # @yield The block to execute for the event
      def trace(key, metadata, &blk)
        prefixed_key = KEYS[key] || "#{key}.graphql"

        # Cache the new keys while making sure not to induce a memory leak
        if KEYS.size < MAX_KEYS_SIZE
          KEYS[key] ||= prefixed_key
        end

        @notifications_engine.instrument(prefixed_key, metadata, &blk)
      end
    end
  end
end
