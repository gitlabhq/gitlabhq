# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentsAreOnCompositeTypes
      def on_fragment_definition(node, parent)
        validate_type_is_composite(node) && super
      end

      def on_inline_fragment(node, parent)
        validate_type_is_composite(node) && super
      end

      private

      def validate_type_is_composite(node)
        node_type = node.type
        if node_type.nil?
          # Inline fragment on the same type
          true
        else
          type_name = node_type.to_query_string
          type_def = @types.type(type_name)
          if type_def.nil? || !type_def.kind.composite?
            add_error(GraphQL::StaticValidation::FragmentsAreOnCompositeTypesError.new(
              "Invalid fragment on type #{type_name} (must be Union, Interface or Object)",
              nodes: node,
              type: type_name
            ))
            false
          else
            true
          end
        end
      end
    end
  end
end
