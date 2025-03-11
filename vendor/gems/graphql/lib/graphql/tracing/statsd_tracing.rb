# frozen_string_literal: true

require "graphql/tracing/platform_tracing"

module GraphQL
  module Tracing
    class StatsdTracing < PlatformTracing
      self.platform_keys = {
        'lex' => "graphql.lex",
        'parse' => "graphql.parse",
        'validate' => "graphql.validate",
        'analyze_query' => "graphql.analyze_query",
        'analyze_multiplex' => "graphql.analyze_multiplex",
        'execute_multiplex' => "graphql.execute_multiplex",
        'execute_query' => "graphql.execute_query",
        'execute_query_lazy' => "graphql.execute_query_lazy",
      }

      # @param statsd [Object] A statsd client
      def initialize(statsd:, **rest)
        @statsd = statsd
        super(**rest)
      end

      def platform_trace(platform_key, key, data)
        @statsd.time(platform_key) do
          yield
        end
      end

      def platform_field_key(type, field)
        "graphql.#{type.graphql_name}.#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "graphql.authorized.#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "graphql.resolve_type.#{type.graphql_name}"
      end
    end
  end
end
