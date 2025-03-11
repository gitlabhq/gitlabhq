# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # This implementation forwards events to a notification handler (i.e.
    # ActiveSupport::Notifications or Dry::Monitor::Notifications)
    # with a `graphql` suffix.
    module NotificationsTrace
      # Initialize a new NotificationsTracing instance
      #
      # @param engine [#instrument(key, metadata, block)] The notifications engine to use
      def initialize(engine:, **rest)
        @notifications_engine = engine
        super
      end

      # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time

      {
        "lex" => "lex.graphql",
        "parse" => "parse.graphql",
        "validate" => "validate.graphql",
        "analyze_multiplex" => "analyze_multiplex.graphql",
        "analyze_query" => "analyze_query.graphql",
        "execute_multiplex" => "execute_multiplex.graphql",
        "execute_query" => "execute_query.graphql",
        "execute_query_lazy" => "execute_query_lazy.graphql",
        "execute_field" => "execute_field.graphql",
        "execute_field_lazy" => "execute_field_lazy.graphql",
        "authorized" => "authorized.graphql",
        "authorized_lazy" => "authorized_lazy.graphql",
        "resolve_type" => "resolve_type.graphql",
        "resolve_type_lazy" => "resolve_type.graphql",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**metadata, &block)
            @notifications_engine.instrument("#{platform_key}", metadata) { super(**metadata, &block) }
          end
        RUBY
      end

      # rubocop:enable Development/NoEvalCop

      include PlatformTrace
    end
  end
end
