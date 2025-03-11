# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby times to Statsd.
    # Passing any Statsd client that implements `.time(name) { ... }` will work.
    #
    # @example Installing this tracer
    #   # eg:
    #   # $statsd = Statsd.new 'localhost', 9125
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Tracing::StatsdTrace, statsd: $statsd
    #   end
    module StatsdTrace
      include PlatformTrace

      # @param statsd [Object] A statsd client
      def initialize(statsd:, **rest)
        @statsd = statsd
        super(**rest)
      end

      # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time

      {
        'lex' => "graphql.lex",
        'parse' => "graphql.parse",
        'validate' => "graphql.validate",
        'analyze_query' => "graphql.analyze_query",
        'analyze_multiplex' => "graphql.analyze_multiplex",
        'execute_multiplex' => "graphql.execute_multiplex",
        'execute_query' => "graphql.execute_query",
        'execute_query_lazy' => "graphql.execute_query_lazy",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**data)
            @statsd.time("#{platform_key}") do
              super
            end
          end
        RUBY
      end

      # rubocop:enable Development/NoEvalCop

      def platform_execute_field(platform_key, &block)
        @statsd.time(platform_key, &block)
      end

      def platform_authorized(key, &block)
        @statsd.time(key, &block)
      end

      alias :platform_resolve_type :platform_authorized

      def platform_field_key(field)
        "graphql.#{field.path}"
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
