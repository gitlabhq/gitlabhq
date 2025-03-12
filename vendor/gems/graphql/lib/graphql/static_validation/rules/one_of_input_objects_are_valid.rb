# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module OneOfInputObjectsAreValid
      def on_input_object(node, parent)
        return super unless parent.is_a?(GraphQL::Language::Nodes::Argument)

        parent_type = get_parent_type(context, parent)
        return super unless parent_type && parent_type.kind.input_object? && parent_type.one_of?

        validate_one_of_input_object(node, context, parent_type)
        super
      end

      private

      def validate_one_of_input_object(ast_node, context, parent_type)
        present_fields = ast_node.arguments.map(&:name)
        input_object_type = parent_type.to_type_signature

        if present_fields.count != 1
          add_error(
            OneOfInputObjectsAreValidError.new(
              "OneOf Input Object '#{input_object_type}' must specify exactly one key.",
              path: context.path,
              nodes: ast_node,
              input_object_type: input_object_type
            )
          )
          return
        end

        field = present_fields.first
        value = ast_node.arguments.first.value

        if value.is_a?(GraphQL::Language::Nodes::NullValue)
          add_error(
            OneOfInputObjectsAreValidError.new(
              "Argument '#{input_object_type}.#{field}' must be non-null.",
              path: [*context.path, field],
              nodes: ast_node.arguments.first,
              input_object_type: input_object_type
            )
          )
          return
        end

        if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          variable_name = value.name
          variable_type = @declared_variables[variable_name].type

          unless variable_type.is_a?(GraphQL::Language::Nodes::NonNullType)
            add_error(
              OneOfInputObjectsAreValidError.new(
                "Variable '#{variable_name}' must be non-nullable to be used for OneOf Input Object '#{input_object_type}'.",
                path: [*context.path, field],
                nodes: ast_node,
                input_object_type: input_object_type
              )
            )
          end
        end
      end
    end
  end
end
