# frozen_string_literal: true

module GraphQL
  class Schema
    # Represents a list type in the schema.
    # Wraps a {Schema::Member} as a list type.
    # @see {Schema::Member::TypeSystemHelpers#to_list_type}
    class List < GraphQL::Schema::Wrapper
      include Schema::Member::ValidatesInput

      # @return [GraphQL::TypeKinds::LIST]
      def kind
        GraphQL::TypeKinds::LIST
      end

      # @return [true]
      def list?
        true
      end

      def to_type_signature
        "[#{@of_type.to_type_signature}]"
      end

      # This is for introspection, where it's expected the name will be `null`
      def graphql_name
        nil
      end

      # Also for implementing introspection
      def description
        nil
      end

      def coerce_result(value, ctx)
        value.map { |i| i.nil? ? nil : of_type.coerce_result(i, ctx) }
      end

      def coerce_input(value, ctx)
        if value.nil?
          nil
        else
          coerced = ensure_array(value).map { |item| item.nil? ? item : of_type.coerce_input(item, ctx) }
          ctx.schema.after_any_lazies(coerced, &:itself)
        end
      end

      def validate_non_null_input(value, ctx, max_errors: nil)
        result = GraphQL::Query::InputValidationResult.new
        ensure_array(value).each_with_index do |item, index|
          item_result = of_type.validate_input(item, ctx)
          unless item_result.valid?
            if max_errors
              if max_errors == 0
                add_max_errors_reached_message(result)
                break
              end

              max_errors -= 1
            end

            result.merge_result!(index, item_result)
          end
        end
        result.valid? ? nil : result
      end

      private

      def ensure_array(value)
        # `Array({ a: 1 })` makes `[[:a, 1]]`, so do it manually
        if value.is_a?(Array)
          value
        else
          [value]
        end
      end

      def add_max_errors_reached_message(result)
        message = "Too many errors processing list variable, max validation error limit reached. Execution aborted"
        item_result = GraphQL::Query::InputValidationResult.from_problem(message)
        result.merge_result!(nil, item_result)
      end
    end
  end
end
