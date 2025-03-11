# frozen_string_literal: true

module GraphQL
  class Subscriptions
    # Detect whether the current operation:
    # - Is a subscription operation
    # - Is completely broadcastable
    #
    # Assign the result to `context.namespace(:subscriptions)[:subscription_broadcastable]`
    # @api private
    # @see Subscriptions#broadcastable? for a public API
    class BroadcastAnalyzer < GraphQL::Analysis::Analyzer
      def initialize(subject)
        super
        @default_broadcastable = subject.schema.subscriptions.default_broadcastable
        # Maybe this will get set to false while analyzing
        @subscription_broadcastable = true
      end

      # Only analyze subscription operations
      def analyze?
        @query.subscription?
      end

      def on_enter_field(node, parent, visitor)
        if (@subscription_broadcastable == false) || visitor.skipping?
          return
        end

        current_field = visitor.field_definition
        current_type = visitor.parent_type_definition
        apply_broadcastable(current_type, current_field)
        if current_type.kind.interface?
          pt = @query.possible_types(current_type)
          pt.each do |object_type|
            ot_field = @query.get_field(object_type, current_field.graphql_name)
            # Inherited fields would be exactly the same object;
            # only check fields that are overrides of the inherited one
            if ot_field && ot_field != current_field
              apply_broadcastable(object_type, ot_field)
            end
          end
        end
      end

      # Assign the result to context.
      # (This method is allowed to return an error, but we don't need to)
      # @return [void]
      def result
        query.context.namespace(:subscriptions)[:subscription_broadcastable] = @subscription_broadcastable
        nil
      end

      private

      # Modify `@subscription_broadcastable` based on `field_defn`'s configuration (and/or the default value)
      def apply_broadcastable(owner_type, field_defn)
        current_field_broadcastable = field_defn.introspection? || field_defn.broadcastable?

        if current_field_broadcastable.nil? && owner_type.respond_to?(:default_broadcastable?)
          current_field_broadcastable = owner_type.default_broadcastable?
        end

        case current_field_broadcastable
        when nil
          query.logger.debug { "`broadcastable: nil` for field: #{field_defn.path}" }
          # If the value wasn't set, mix in the default value:
          # - If the default is false and the current value is true, make it false
          # - If the default is true and the current value is true, it stays true
          # - If the default is false and the current value is false, keep it false
          # - If the default is true and the current value is false, keep it false
          @subscription_broadcastable = @subscription_broadcastable && @default_broadcastable
        when false
          query.logger.debug { "`broadcastable: false` for field: #{field_defn.path}" }
          # One non-broadcastable field is enough to make the whole subscription non-broadcastable
          @subscription_broadcastable = false
        when true
          # Leave `@broadcastable_query` true if it's already true,
          # but don't _set_ it to true if it was set to false by something else.
          # Actually, just leave it!
        else
          raise ArgumentError, "Unexpected `.broadcastable?` value for #{field_defn.path}: #{current_field_broadcastable}"
        end
      end
    end
  end
end
