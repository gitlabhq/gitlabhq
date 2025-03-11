# frozen_string_literal: true

module GraphQL
  module Tracing
    module PlatformTrace
      def initialize(trace_scalars: false, **_options)
        @trace_scalars = trace_scalars

        @platform_key_cache = Hash.new { |h, mod| h[mod] = mod::KeyCache.new }
        super
      end

      module BaseKeyCache
        def initialize
          @platform_field_key_cache = Hash.new { |h, k| h[k] = platform_field_key(k) }
          @platform_authorized_key_cache = Hash.new { |h, k| h[k] = platform_authorized_key(k) }
          @platform_resolve_type_key_cache = Hash.new { |h, k| h[k] = platform_resolve_type_key(k) }
        end

        attr_reader :platform_field_key_cache, :platform_authorized_key_cache, :platform_resolve_type_key_cache
      end


      def platform_execute_field_lazy(*args, &block)
        platform_execute_field(*args, &block)
      end

      def platform_authorized_lazy(key, &block)
        platform_authorized(key, &block)
      end

      def platform_resolve_type_lazy(key, &block)
        platform_resolve_type(key, &block)
      end

      def self.included(child_class)
        key_methods_class = Class.new {
          include(child_class)
          include(BaseKeyCache)
        }
        child_class.const_set(:KeyCache, key_methods_class)

        # rubocop:disable Development/NoEvalCop This eval takes static inputs at load-time

        [:execute_field, :execute_field_lazy].each do |field_trace_method|
          if !child_class.method_defined?(field_trace_method)
            child_class.module_eval <<-RUBY, __FILE__, __LINE__
              def #{field_trace_method}(query:, field:, ast_node:, arguments:, object:)
                return_type = field.type.unwrap
                trace_field = if return_type.kind.scalar? || return_type.kind.enum?
                  (field.trace.nil? && @trace_scalars) || field.trace
                else
                  true
                end
                platform_key = if trace_field
                  @platform_key_cache[#{child_class}].platform_field_key_cache[field]
                else
                  nil
                end
                if platform_key && trace_field
                  platform_#{field_trace_method}(platform_key) do
                    super
                  end
                else
                  super
                end
              end
            RUBY
          end
        end


        [:authorized, :authorized_lazy].each do |auth_trace_method|
          if !child_class.method_defined?(auth_trace_method)
            child_class.module_eval <<-RUBY, __FILE__, __LINE__
              def #{auth_trace_method}(type:, query:, object:)
                platform_key = @platform_key_cache[#{child_class}].platform_authorized_key_cache[type]
                platform_#{auth_trace_method}(platform_key) do
                  super
                end
              end
            RUBY
          end
        end

        [:resolve_type, :resolve_type_lazy].each do |rt_trace_method|
          if !child_class.method_defined?(rt_trace_method)
            child_class.module_eval <<-RUBY, __FILE__, __LINE__
              def #{rt_trace_method}(query:, type:, object:)
                platform_key = @platform_key_cache[#{child_class}].platform_resolve_type_key_cache[type]
                platform_#{rt_trace_method}(platform_key) do
                  super
                end
              end
            RUBY
          end

          # rubocop:enable Development/NoEvalCop
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
    end
  end
end
