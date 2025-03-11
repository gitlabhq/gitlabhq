# frozen_string_literal: true

module GraphQL
  module Tracing
    # Each platform provides:
    # - `.platform_keys`
    # - `#platform_trace`
    # - `#platform_field_key(type, field)`
    # @api private
    class PlatformTracing
      class << self
        attr_accessor :platform_keys

        def inherited(child_class)
          child_class.platform_keys = self.platform_keys
        end
      end

      def initialize(options = {})
        @options = options
        @platform_keys = self.class.platform_keys
        @trace_scalars = options.fetch(:trace_scalars, false)
      end

      def trace(key, data)
        case key
        when "lex", "parse", "validate", "analyze_query", "analyze_multiplex", "execute_query", "execute_query_lazy", "execute_multiplex"
          platform_key = @platform_keys.fetch(key)
          platform_trace(platform_key, key, data) do
            yield
          end
        when "execute_field", "execute_field_lazy"
          field = data[:field]
          return_type = field.type.unwrap
          trace_field = if return_type.kind.scalar? || return_type.kind.enum?
            (field.trace.nil? && @trace_scalars) || field.trace
          else
            true
          end

          platform_key = if trace_field
            context = data.fetch(:query).context
            cached_platform_key(context, field, :field) { platform_field_key(field.owner, field) }
          else
            nil
          end

          if platform_key && trace_field
            platform_trace(platform_key, key, data) do
              yield
            end
          else
            yield
          end
        when "authorized", "authorized_lazy"
          type = data.fetch(:type)
          context = data.fetch(:context)
          platform_key = cached_platform_key(context, type, :authorized) { platform_authorized_key(type) }
          platform_trace(platform_key, key, data) do
            yield
          end
        when "resolve_type", "resolve_type_lazy"
          type = data.fetch(:type)
          context = data.fetch(:context)
          platform_key = cached_platform_key(context, type, :resolve_type) { platform_resolve_type_key(type) }
          platform_trace(platform_key, key, data) do
            yield
          end
        else
          # it's a custom key
          yield
        end
      end

      def self.use(schema_defn, options = {})
        if options[:legacy_tracing]
          tracer = self.new(**options)
          schema_defn.tracer(tracer)
        else
          tracing_name = self.name.split("::").last
          trace_name = tracing_name.sub("Tracing", "Trace")
          if GraphQL::Tracing.const_defined?(trace_name, false)
            trace_module = GraphQL::Tracing.const_get(trace_name)
            warn("`use(#{self.name})` is deprecated, use the equivalent `trace_with(#{trace_module.name})` instead. More info: https://graphql-ruby.org/queries/tracing.html")
            schema_defn.trace_with(trace_module, **options)
          else
            warn("`use(#{self.name})` and `Tracing::PlatformTracing` are deprecated. Use a `trace_with(...)` module instead. More info: https://graphql-ruby.org/queries/tracing.html. Please open an issue on the GraphQL-Ruby repo if you want to discuss further!")
            tracer = self.new(**options)
          schema_defn.tracer(tracer, silence_deprecation_warning: true)
          end
        end
      end

      private

      # Get the transaction name based on the operation type and name if possible, or fall back to a user provided
      # one. Useful for anonymous queries.
      def transaction_name(query)
        selected_op = query.selected_operation
        txn_name = if selected_op
          op_type = selected_op.operation_type
          op_name = selected_op.name || fallback_transaction_name(query.context) || "anonymous"
          "#{op_type}.#{op_name}"
        else
          "query.anonymous"
        end
        "GraphQL/#{txn_name}"
      end

      def fallback_transaction_name(context)
        context[:tracing_fallback_transaction_name]
      end

      attr_reader :options

      # Different kind of schema objects have different kinds of keys:
      #
      # - Object types: `.authorized`
      # - Union/Interface types: `.resolve_type`
      # - Fields: execution
      #
      # So, they can all share one cache.
      #
      # If the key isn't present, the given block is called and the result is cached for `key`.
      #
      # @param ctx [GraphQL::Query::Context]
      # @param key [Class, GraphQL::Field] A part of the schema
      # @param trace_phase [Symbol] The stage of execution being traced (used by OpenTelementry tracing)
      # @return [String]
      def cached_platform_key(ctx, key, trace_phase)
        cache = ctx.namespace(self.class)[:platform_key_cache] ||= {}
        cache.fetch(key) { cache[key] = yield }
      end
    end
  end
end
