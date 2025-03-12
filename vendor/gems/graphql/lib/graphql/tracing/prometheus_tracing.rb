# frozen_string_literal: true

require "graphql/tracing/platform_tracing"

module GraphQL
  module Tracing
    class PrometheusTracing < PlatformTracing
      DEFAULT_WHITELIST = ['execute_field', 'execute_field_lazy'].freeze
      DEFAULT_COLLECTOR_TYPE = 'graphql'.freeze

      self.platform_keys = {
        'lex' => "graphql.lex",
        'parse' => "graphql.parse",
        'validate' => "graphql.validate",
        'analyze_query' => "graphql.analyze",
        'analyze_multiplex' => "graphql.analyze",
        'execute_multiplex' => "graphql.execute",
        'execute_query' => "graphql.execute",
        'execute_query_lazy' => "graphql.execute",
        'execute_field' => "graphql.execute",
        'execute_field_lazy' => "graphql.execute"
      }

      def initialize(opts = {})
        @client = opts[:client] || PrometheusExporter::Client.default
        @keys_whitelist = opts[:keys_whitelist] || DEFAULT_WHITELIST
        @collector_type = opts[:collector_type] || DEFAULT_COLLECTOR_TYPE

        super opts
      end

      def platform_trace(platform_key, key, _data, &block)
        return yield unless @keys_whitelist.include?(key)
        instrument_execution(platform_key, key, &block)
      end

      def platform_field_key(type, field)
        "#{type.graphql_name}.#{field.graphql_name}"
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end

      private

      def instrument_execution(platform_key, key, &block)
        start = ::Process.clock_gettime ::Process::CLOCK_MONOTONIC
        result = block.call
        duration = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start
        observe platform_key, key, duration
        result
      end

      def observe(platform_key, key, duration)
        @client.send_json(
          type: @collector_type,
          duration: duration,
          platform_key: platform_key,
          key: key
        )
      end
    end
  end
end
