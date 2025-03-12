# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby times to Prometheus.
    #
    # The PrometheusExporter server must be run with a custom type collector that extends `GraphQL::Tracing::PrometheusTracing::GraphQLCollector`.
    #
    # @example Adding this trace to your schema
    #   require 'prometheus_exporter/client'
    #
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::PrometheusTrace
    #   end
    #
    # @example Running a custom type collector
    #   # lib/graphql_collector.rb
    #   if defined?(PrometheusExporter::Server)
    #     require 'graphql/tracing'
    #
    #     class GraphQLCollector < GraphQL::Tracing::PrometheusTrace::GraphQLCollector
    #     end
    #   end
    #
    #    # Then run:
    #    # bundle exec prometheus_exporter -a lib/graphql_collector.rb
    module PrometheusTrace
      if defined?(PrometheusExporter::Server)
        autoload :GraphQLCollector, "graphql/tracing/prometheus_trace/graphql_collector"
      end
      include PlatformTrace

      def initialize(client: PrometheusExporter::Client.default, keys_whitelist: ["execute_field", "execute_field_lazy"], collector_type: "graphql", **rest)
        @client = client
        @keys_whitelist = keys_whitelist
        @collector_type = collector_type

        super(**rest)
      end

      # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time

      {
        'lex' => "graphql.lex",
        'parse' => "graphql.parse",
        'validate' => "graphql.validate",
        'analyze_query' => "graphql.analyze",
        'analyze_multiplex' => "graphql.analyze",
        'execute_multiplex' => "graphql.execute",
        'execute_query' => "graphql.execute",
        'execute_query_lazy' => "graphql.execute",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**data)
            instrument_prometheus_execution("#{platform_key}", "#{trace_method}") { super }
          end
        RUBY
      end

      # rubocop:enable Development/NoEvalCop

      def platform_execute_field(platform_key, &block)
        instrument_prometheus_execution(platform_key, "execute_field", &block)
      end

      def platform_execute_field_lazy(platform_key, &block)
        instrument_prometheus_execution(platform_key, "execute_field_lazy", &block)
      end

      def platform_authorized(platform_key, &block)
        instrument_prometheus_execution(platform_key, "authorized", &block)
      end

      def platform_authorized_lazy(platform_key, &block)
        instrument_prometheus_execution(platform_key, "authorized_lazy", &block)
      end

      def platform_resolve_type(platform_key, &block)
        instrument_prometheus_execution(platform_key, "resolve_type", &block)
      end

      def platform_resolve_type_lazy(platform_key, &block)
        instrument_prometheus_execution(platform_key, "resolve_type_lazy", &block)
      end

      def platform_field_key(field)
        field.path
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end

      private

      def instrument_prometheus_execution(platform_key, key, &block)
        if @keys_whitelist.include?(key)
          start = ::Process.clock_gettime ::Process::CLOCK_MONOTONIC
          result = block.call
          duration = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start
          @client.send_json(
            type: @collector_type,
            duration: duration,
            platform_key: platform_key,
            key: key
          )
          result
        else
          yield
        end
      end
    end
  end
end
