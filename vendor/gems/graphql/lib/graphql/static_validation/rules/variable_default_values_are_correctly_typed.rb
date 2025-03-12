# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module VariableDefaultValuesAreCorrectlyTyped
      def on_variable_definition(node, parent)
        if !node.default_value.nil?
          value = node.default_value
          type = context.schema.type_from_ast(node.type, context: context)
          if type.nil?
            # This is handled by another validator
          else
            validation_result = context.validate_literal(value, type)

            if !validation_result.valid?
              problems = validation_result.problems
              first_problem = problems && problems.first
              if first_problem
                error_message = first_problem["explanation"]
              end

              error_message ||= "Default value for $#{node.name} doesn't match type #{type.to_type_signature}"
              add_error(GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTypedError.new(
                error_message,
                nodes: node,
                name: node.name,
                type: type.to_type_signature,
                error_type: VariableDefaultValuesAreCorrectlyTypedError::VIOLATIONS[:INVALID_TYPE],
              ))
            end
          end
        end

        super
      end
    end
  end
end
