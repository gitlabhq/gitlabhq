# frozen_string_literal: true

module GraphQL
  class Query
    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context

      class ExecutionErrors
        def initialize(ctx)
          @context = ctx
        end

        def add(err_or_msg)
          err = case err_or_msg
          when String
            GraphQL::ExecutionError.new(err_or_msg)
          when GraphQL::ExecutionError
            err_or_msg
          else
            raise ArgumentError, "expected String or GraphQL::ExecutionError, not #{err_or_msg.class} (#{err_or_msg.inspect})"
          end
          # This will assign ast_node and path
          @context.add_error(err)
        end

        alias :>> :add
        alias :push :add
      end

      extend Forwardable

      # @return [Array<GraphQL::ExecutionError>] errors returned during execution
      attr_reader :errors

      # @return [GraphQL::Query] The query whose context this is
      attr_reader :query

      # @return [GraphQL::Schema]
      attr_reader :schema

      # @return [Array<String, Integer>] The current position in the result
      attr_reader :path

      # Make a new context which delegates key lookup to `values`
      # @param query [GraphQL::Query] the query who owns this context
      # @param values [Hash] A hash of arbitrary values which will be accessible at query-time
      def initialize(query:, schema: query.schema, values:)
        @query = query
        @schema = schema
        @provided_values = values || {}
        # Namespaced storage, where user-provided values are in `nil` namespace:
        @storage = Hash.new { |h, k| h[k] = {} }
        @storage[nil] = @provided_values
        @errors = []
        @path = []
        @value = nil
        @context = self # for SharedMethods TODO delete sharedmethods
        @scoped_context = ScopedContext.new(self)
      end

      # @return [Hash] A hash that will be added verbatim to the result hash, as `"extensions" => { ... }`
      def response_extensions
        namespace(:__query_result_extensions__)
      end

      def dataloader
        @dataloader ||= self[:dataloader] || (query.multiplex ? query.multiplex.dataloader : schema.dataloader_class.new)
      end

      # @api private
      attr_writer :interpreter

      # @api private
      attr_writer :value

      # @api private
      attr_reader :scoped_context

      def []=(key, value)
        @provided_values[key] = value
      end

      def_delegators :@query, :trace

      def types
        @types ||= @query.types
      end

      attr_writer :types

      RUNTIME_METADATA_KEYS = Set.new([:current_object, :current_arguments, :current_field, :current_path])
      # @!method []=(key, value)
      #   Reassign `key` to the hash passed to {Schema#execute} as `context:`

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      def [](key)
        if @scoped_context.key?(key)
          @scoped_context[key]
        elsif @provided_values.key?(key)
          @provided_values[key]
        elsif RUNTIME_METADATA_KEYS.include?(key)
          if key == :current_path
            current_path
          else
            (current_runtime_state = Fiber[:__graphql_runtime_info]) &&
              (query_runtime_state = current_runtime_state[@query]) &&
              (query_runtime_state.public_send(key))
          end
        else
          # not found
          nil
        end
      end

      # Return this value to tell the runtime
      # to exclude this field from the response altogether
      def skip
        GraphQL::Execution::SKIP
      end

      # Add error at query-level.
      # @param error [GraphQL::ExecutionError] an execution error
      # @return [void]
      def add_error(error)
        if !error.is_a?(ExecutionError)
          raise TypeError, "expected error to be a ExecutionError, but was #{error.class}"
        end
        errors << error
        nil
      end

      # @example Print the GraphQL backtrace during field resolution
      #   puts ctx.backtrace
      #
      # @return [GraphQL::Backtrace] The backtrace for this point in query execution
      def backtrace
        GraphQL::Backtrace.new(self)
      end

      def execution_errors
        @execution_errors ||= ExecutionErrors.new(self)
      end

      def current_path
        current_runtime_state = Fiber[:__graphql_runtime_info]
        query_runtime_state = current_runtime_state && current_runtime_state[@query]

        path = query_runtime_state &&
          (result = query_runtime_state.current_result) &&
          (result.path)
        if path && (rn = query_runtime_state.current_result_name)
          path = path.dup
          path.push(rn)
        end
        path
      end

      def delete(key)
        if @scoped_context.key?(key)
          @scoped_context.delete(key)
        else
          @provided_values.delete(key)
        end
      end

      UNSPECIFIED_FETCH_DEFAULT = Object.new

      def fetch(key, default = UNSPECIFIED_FETCH_DEFAULT)
        if RUNTIME_METADATA_KEYS.include?(key)
          (runtime = Fiber[:__graphql_runtime_info]) &&
            (query_runtime_state = runtime[@query]) &&
            (query_runtime_state.public_send(key))
        elsif @scoped_context.key?(key)
          scoped_context[key]
        elsif @provided_values.key?(key)
          @provided_values[key]
        elsif default != UNSPECIFIED_FETCH_DEFAULT
          default
        elsif block_given?
          yield(self, key)
        else
          raise KeyError.new(key: key)
        end
      end

      def dig(key, *other_keys)
        if RUNTIME_METADATA_KEYS.include?(key)
          (current_runtime_state = Fiber[:__graphql_runtime_info]) &&
            (query_runtime_state = current_runtime_state[@query]) &&
            (obj = query_runtime_state.public_send(key)) &&
            if other_keys.empty?
              obj
            else
              obj.dig(*other_keys)
            end
        elsif @scoped_context.key?(key)
          @scoped_context.dig(key, *other_keys)
        else
          @provided_values.dig(key, *other_keys)
        end
      end

      def to_h
        if (current_scoped_context = @scoped_context.merged_context)
          @provided_values.merge(current_scoped_context)
        else
          @provided_values
        end
      end

      alias :to_hash :to_h

      def key?(key)
        @scoped_context.key?(key) || @provided_values.key?(key)
      end

      # @return [GraphQL::Schema::Warden]
      def warden
        @warden ||= (@query && @query.warden)
      end

      # @api private
      attr_writer :warden

      # Get an isolated hash for `ns`. Doesn't affect user-provided storage.
      # @param ns [Object] a usage-specific namespace identifier
      # @return [Hash] namespaced storage
      def namespace(ns)
        if ns == :interpreter
          self
        else
          @storage[ns]
        end
      end

      # @return [Boolean] true if this namespace was accessed before
      def namespace?(ns)
        @storage.key?(ns)
      end

      def logger
        @query && @query.logger
      end

      def inspect
        "#<Query::Context ...>"
      end

      def scoped_merge!(hash)
        @scoped_context.merge!(hash)
      end

      def scoped_set!(key, value)
        scoped_merge!(key => value)
        nil
      end

      # Use this when you need to do a scoped set _inside_ a lazy-loaded (or batch-loaded)
      # block of code.
      #
      # @example using scoped context inside a promise
      #   scoped_ctx = context.scoped
      #   SomeBatchLoader.load(...).then do |thing|
      #     # use a scoped_ctx which was created _before_ dataloading:
      #     scoped_ctx.set!(:thing, thing)
      #   end
      # @return [Context::Scoped]
      def scoped
        Scoped.new(@scoped_context, current_path)
      end

      class Scoped
        def initialize(scoped_context, path)
          @path = path
          @scoped_context = scoped_context
        end

        def merge!(hash)
          @scoped_context.merge!(hash, at: @path)
        end

        def set!(key, value)
          @scoped_context.merge!({ key => value }, at: @path)
          nil
        end
      end
    end
  end
end

require "graphql/query/context/scoped_context"
