# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module MutationRootExists
      def on_operation_definition(node, _parent)
        if node.operation_type == 'mutation' && context.query.types.mutation_root.nil?
          add_error(GraphQL::StaticValidation::MutationRootExistsError.new(
            'Schema is not configured for mutations',
            nodes: node
          ))
        else
          super
        end
      end
    end
  end
end
