# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module SubscriptionRootExists
      def on_operation_definition(node, _parent)
        if node.operation_type == "subscription" && context.types.subscription_root.nil?
          add_error(GraphQL::StaticValidation::SubscriptionRootExistsError.new(
            'Schema is not configured for subscriptions',
            nodes: node
          ))
        else
          super
        end
      end
    end
  end
end
