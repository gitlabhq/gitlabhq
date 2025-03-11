# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module ArgumentLiteralsAreCompatible
      def on_argument(node, parent)
        # Check the child arguments first;
        # don't add a new error if one of them reports an error
        super

        # Don't validate variables here
        if node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          return
        end

        if @context.schema.error_bubbling || context.errors.none? { |err| err.path.take(@path.size) == @path }
          parent_defn = parent_definition(parent)

          if parent_defn && (arg_defn = @types.argument(parent_defn, node.name))
            validation_result = context.validate_literal(node.value, arg_defn.type)
            if !validation_result.valid?
              kind_of_node = node_type(parent)
              error_arg_name = parent_name(parent, parent_defn)
              string_value = if node.value == Float::INFINITY
                ""
              else
                " (#{GraphQL::Language::Printer.new.print(node.value)})"
              end

              problems = validation_result.problems
              first_problem = problems && problems.first
              if first_problem
                message = first_problem["message"]
                # This is some legacy stuff from when `CoercionError` was raised thru the stack
                if message
                  coerce_extensions = first_problem["extensions"] || {
                    "code" => "argumentLiteralsIncompatible"
                  }
                end
              end

              error_options = {
                nodes: parent,
                type: kind_of_node,
                argument_name: node.name,
                argument: arg_defn,
                value: node.value
              }
              if coerce_extensions
                error_options[:coerce_extensions] = coerce_extensions
              end

              message ||= "Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value#{string_value}. Expected type '#{arg_defn.type.to_type_signature}'."

              error = GraphQL::StaticValidation::ArgumentLiteralsAreCompatibleError.new(
                message,
                **error_options
              )

              add_error(error)
            end
          end
        end
      end
    end
  end
end
