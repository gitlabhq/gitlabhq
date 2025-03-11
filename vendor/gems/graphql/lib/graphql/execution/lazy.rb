# frozen_string_literal: true
require "graphql/execution/lazy/lazy_method_map"

module GraphQL
  module Execution
    # This wraps a value which is available, but not yet calculated, like a promise or future.
    #
    # Calling `#value` will trigger calculation & return the "lazy" value.
    #
    # This is an itty-bitty promise-like object, with key differences:
    # - It has only two states, not-resolved and resolved
    # - It has no error-catching functionality
    # @api private
    class Lazy
      attr_reader :field

      # Create a {Lazy} which will get its inner value by calling the block
      # @param field [GraphQL::Schema::Field]
      # @param get_value_func [Proc] a block to get the inner value (later)
      def initialize(field: nil, &get_value_func)
        @get_value_func = get_value_func
        @resolved = false
        @field = field
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        if !@resolved
          @resolved = true
          v = @get_value_func.call
          if v.is_a?(Lazy)
            v = v.value
          end
          @value = v
        end

        # `SKIP` was made into a subclass of `GraphQL::Error` to improve runtime performance
        # (fewer clauses in a hot `case` block), but now it requires special handling here.
        # I think it's still worth it for the performance win, but if the number of special
        # cases grows, then maybe it's worth rethinking somehow.
        if @value.is_a?(StandardError) && @value != GraphQL::Execution::SKIP
          raise @value
        else
          @value
        end
      end

      # @return [Lazy] A {Lazy} whose value depends on another {Lazy}, plus any transformations in `block`
      def then
        self.class.new {
          yield(value)
        }
      end

      # @param lazies [Array<Object>] Maybe-lazy objects
      # @return [Lazy] A lazy which will sync all of `lazies`
      def self.all(lazies)
        self.new {
          lazies.map { |l| l.is_a?(Lazy) ? l.value : l }
        }
      end

      # This can be used for fields which _had no_ lazy results
      # @api private
      NullResult = Lazy.new(){}
      NullResult.value
    end
  end
end
