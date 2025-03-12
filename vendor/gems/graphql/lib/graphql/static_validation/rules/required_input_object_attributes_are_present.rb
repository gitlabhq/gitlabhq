# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module RequiredInputObjectAttributesArePresent
      def on_input_object(node, parent)
        if parent.is_a? GraphQL::Language::Nodes::Argument
          validate_input_object(node, context, parent)
        end
        super
      end

      private

      def get_parent_type(context, parent)
        # If argument_definition is defined we're at nested object
        # and need to refer to the containing input object type rather
        # than the field_definition.
        # h/t @rmosolgo
        arg_defn = context.argument_definition

        # Double checking that arg_defn is an input object as nested
        # scalars, namely JSON, can make it to this branch
        defn = if arg_defn && arg_defn.type.unwrap.kind.input_object?
          arg_defn.type.unwrap
        else
          context.directive_definition || context.field_definition
        end

        parent_type = context.types.argument(defn, parent_name(parent, defn))
        parent_type ? parent_type.type.unwrap : nil
      end

      def validate_input_object(ast_node, context, parent)
        parent_type = get_parent_type(context, parent)
        return unless parent_type && parent_type.kind.input_object?

        required_fields = context.types.arguments(parent_type)
          .select{ |arg| arg.type.kind.non_null? && !arg.default_value? }
          .map!(&:graphql_name)

        present_fields = ast_node.arguments.map(&:name)
        missing_fields = required_fields - present_fields

        missing_fields.each do |missing_field|
          path = [*context.path, missing_field]
          missing_field_type = context.types.argument(parent_type, missing_field).type
          add_error(RequiredInputObjectAttributesArePresentError.new(
            "Argument '#{missing_field}' on InputObject '#{parent_type.to_type_signature}' is required. Expected type #{missing_field_type.to_type_signature}",
            argument_name: missing_field,
            argument_type: missing_field_type.to_type_signature,
            input_object_type: parent_type.to_type_signature,
            path: path,
            nodes: ast_node,
          ))
        end
      end
    end
  end
end
