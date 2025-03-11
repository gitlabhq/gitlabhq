# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # A tracer for reporting to DataDog
    # @example Adding this tracer to your schema
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::DataDogTrace
    #   end
    module DataDogTrace
      # @param tracer [#trace] Deprecated
      # @param analytics_enabled [Boolean] Deprecated
      # @param analytics_sample_rate [Float] Deprecated
      def initialize(tracer: nil, analytics_enabled: false, analytics_sample_rate: 1.0, service: nil, **rest)
        if tracer.nil?
          tracer = defined?(Datadog::Tracing) ? Datadog::Tracing : Datadog.tracer
        end
        @tracer = tracer

        @analytics_enabled = analytics_enabled
        @analytics_sample_rate = analytics_sample_rate

        @service_name = service
        @has_prepare_span = respond_to?(:prepare_span)
        super
      end

      # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time

      {
        'lex' => 'lex.graphql',
        'parse' => 'parse.graphql',
        'validate' => 'validate.graphql',
        'analyze_query' => 'analyze.graphql',
        'analyze_multiplex' => 'analyze.graphql',
        'execute_multiplex' => 'execute.graphql',
        'execute_query' => 'execute.graphql',
        'execute_query_lazy' => 'execute.graphql',
      }.each do |trace_method, trace_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**data)
            @tracer.trace("#{trace_key}", service: @service_name, type: 'custom') do |span|
                span.set_tag('component', 'graphql')
                span.set_tag('operation', '#{trace_method}')

              #{
                if trace_method == 'execute_multiplex'
                  <<-RUBY
                  operations = data[:multiplex].queries.map(&:selected_operation_name).join(', ')

                  resource = if operations.empty?
                    first_query = data[:multiplex].queries.first
                    fallback_transaction_name(first_query && first_query.context)
                  else
                    operations
                  end
                  span.resource = resource if resource

                  # [Deprecated] will be removed in the future
                  span.set_metric('_dd1.sr.eausr', @analytics_sample_rate) if @analytics_enabled
                  RUBY
                elsif trace_method == 'execute_query'
                  <<-RUBY
                  span.set_tag(:selected_operation_name, data[:query].selected_operation_name)
                  span.set_tag(:selected_operation_type, data[:query].selected_operation.operation_type)
                  span.set_tag(:query_string, data[:query].query_string)
                  RUBY
                end
              }
              if @has_prepare_span
                prepare_span("#{trace_method.sub("platform_", "")}", data, span)
              end
              super
            end
          end
        RUBY
      end

      # rubocop:enable Development/NoEvalCop

      def execute_field_span(span_key, query, field, ast_node, arguments, object)
        return_type = field.type.unwrap
        trace_field = if return_type.kind.scalar? || return_type.kind.enum?
          (field.trace.nil? && @trace_scalars) || field.trace
        else
          true
        end
        platform_key = if trace_field
          @platform_key_cache[DataDogTrace].platform_field_key_cache[field]
        else
          nil
        end
        if platform_key && trace_field
          @tracer.trace(platform_key, service: @service_name, type: 'custom') do |span|
            span.set_tag('component', 'graphql')
            span.set_tag('operation', span_key)

            if @has_prepare_span
              prepare_span_data = { query: query, field: field, ast_node: ast_node, arguments: arguments, object: object }
              prepare_span(span_key, prepare_span_data, span)
            end
            yield
          end
        else
          yield
        end
      end
      def execute_field(query:, field:, ast_node:, arguments:, object:)
        execute_field_span("execute_field", query, field, ast_node, arguments, object) do
          super(query: query, field: field, ast_node: ast_node, arguments: arguments, object: object)
        end
      end

      def execute_field_lazy(query:, field:, ast_node:, arguments:, object:)
        execute_field_span("execute_field_lazy", query, field, ast_node, arguments, object) do
          super(query: query, field: field, ast_node: ast_node, arguments: arguments, object: object)
        end
      end

      def authorized(query:, type:, object:)
        authorized_span("authorized", object, type, query) do
          super(query: query, type: type, object: object)
        end
      end

      def authorized_span(span_key, object, type, query)
        platform_key = @platform_key_cache[DataDogTrace].platform_authorized_key_cache[type]
        @tracer.trace(platform_key, service: @service_name, type: 'custom') do |span|
          span.set_tag('component', 'graphql')
          span.set_tag('operation', span_key)

          if @has_prepare_span
            prepare_span(span_key, {object: object, type: type, query: query}, span)
          end
          yield
        end
      end

      def authorized_lazy(object:, type:, query:)
        authorized_span("authorized_lazy", object, type, query) do
          super(query: query, type: type, object: object)
        end
      end

      def resolve_type(object:, type:, query:)
        resolve_type_span("resolve_type", object, type, query) do
          super(object: object, query: query, type: type)
        end
      end

      def resolve_type_lazy(object:, type:, query:)
        resolve_type_span("resolve_type_lazy", object, type, query) do
          super(object: object, query: query, type: type)
        end
      end

      def resolve_type_span(span_key, object, type, query)
        platform_key = @platform_key_cache[DataDogTrace].platform_resolve_type_key_cache[type]
        @tracer.trace(platform_key, service: @service_name, type: 'custom') do |span|
          span.set_tag('component', 'graphql')
          span.set_tag('operation', span_key)

          if @has_prepare_span
            prepare_span(span_key, {object: object, type: type, query: query}, span)
          end
          yield
        end
      end

      include PlatformTrace

      # Implement this method in a subclass to apply custom tags to datadog spans
      # @param key [String] The event being traced
      # @param data [Hash] The runtime data for this event (@see GraphQL::Tracing for keys for each event)
      # @param span [Datadog::Tracing::SpanOperation] The datadog span for this event
      # def prepare_span(key, data, span)
      # end

      def platform_field_key(field)
        field.path
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end
    end
  end
end
