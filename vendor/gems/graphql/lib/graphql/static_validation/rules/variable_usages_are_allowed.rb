# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module VariableUsagesAreAllowed
      def initialize(*)
        super
        # holds { name => ast_node } pairs
        @declared_variables = {}
      end

      def on_operation_definition(node, parent)
        @declared_variables = node.variables.each_with_object({}) { |var, memo| memo[var.name] = var }
        super
      end

      def on_argument(node, parent)
        node_values = if node.value.is_a?(Array)
          node.value
        else
          [node.value]
        end
        node_values = node_values.select { |value| value.is_a? GraphQL::Language::Nodes::VariableIdentifier }

        if !node_values.empty?
          argument_owner = case parent
          when GraphQL::Language::Nodes::Field
            context.field_definition
          when GraphQL::Language::Nodes::Directive
            context.directive_definition
          when GraphQL::Language::Nodes::InputObject
            arg_type = context.argument_definition.type.unwrap
            if arg_type.kind.input_object?
              arg_type
            else
              # This is some kind of error
              nil
            end
          else
            raise("Unexpected argument parent: #{parent}")
          end

          node_values.each do |node_value|
            var_defn_ast = @declared_variables[node_value.name]
            # Might be undefined :(
            # VariablesAreUsedAndDefined can't finalize its search until the end of the document.
            var_defn_ast && argument_owner && validate_usage(argument_owner, node, var_defn_ast)
          end
        end
        super
      end

      private

      def validate_usage(argument_owner, arg_node, ast_var)
        var_type = context.schema.type_from_ast(ast_var.type, context: context)
        if var_type.nil?
          return
        end
        if !ast_var.default_value.nil?
          unless var_type.kind.non_null?
            # If the value is required, but the argument is not,
            # and yet there's a non-nil default, then we impliclty
            # make the argument also a required type.
            var_type = var_type.to_non_null_type
          end
        end

        arg_defn = @types.argument(argument_owner, arg_node.name)
        arg_defn_type = arg_defn.type

        # If the argument is non-null, but it was given a default value,
        # then treat it as nullable in practice, see https://github.com/rmosolgo/graphql-ruby/issues/3793
        if arg_defn_type.non_null? && arg_defn.default_value?
          arg_defn_type = arg_defn_type.of_type
        end

        var_inner_type = var_type.unwrap
        arg_inner_type = arg_defn_type.unwrap

        var_type = wrap_var_type_with_depth_of_arg(var_type, arg_node)

        if var_inner_type != arg_inner_type
          create_error("Type mismatch", var_type, ast_var, arg_defn, arg_node)
        elsif list_dimension(var_type) != list_dimension(arg_defn_type)
          create_error("List dimension mismatch", var_type, ast_var, arg_defn, arg_node)
        elsif !non_null_levels_match(arg_defn_type, var_type)
          create_error("Nullability mismatch", var_type, ast_var, arg_defn, arg_node)
        end
      end

      def create_error(error_message, var_type, ast_var, arg_defn, arg_node)
        add_error(GraphQL::StaticValidation::VariableUsagesAreAllowedError.new(
          "#{error_message} on variable $#{ast_var.name} and argument #{arg_node.name} (#{var_type.to_type_signature} / #{arg_defn.type.to_type_signature})",
          nodes: arg_node,
          name: ast_var.name,
          type: var_type.to_type_signature,
          argument: arg_node.name,
          error: error_message
        ))
      end

      def wrap_var_type_with_depth_of_arg(var_type, arg_node)
        arg_node_value = arg_node.value
        return var_type unless arg_node_value.is_a?(Array)
        new_var_type = var_type

        depth_of_array(arg_node_value).times do
          # Since the array _is_ present, treat it like a non-null type
          # (It satisfies a non-null requirement AND a nullable requirement)
          new_var_type = new_var_type.to_list_type.to_non_null_type
        end

        new_var_type
      end

      # @return [Integer] Returns the max depth of `array`, or `0` if it isn't an array at all
      def depth_of_array(array)
        case array
        when Array
          max_child_depth = 0
          array.each do |item|
            item_depth = depth_of_array(item)
            if item_depth > max_child_depth
              max_child_depth = item_depth
            end
          end
          1 + max_child_depth
        else
          0
        end
      end

      def list_dimension(type)
        if type.kind.list?
          1 + list_dimension(type.of_type)
        elsif type.kind.non_null?
          list_dimension(type.of_type)
        else
          0
        end
      end

      def non_null_levels_match(arg_type, var_type)
        if arg_type.kind.non_null? && !var_type.kind.non_null?
          false
        elsif arg_type.kind.wraps? && var_type.kind.wraps?
          # If var_type is a non-null wrapper for a type, and arg_type is nullable, peel off the wrapper
          # That way, a var_type of `[DairyAnimal]!` works with an arg_type of `[DairyAnimal]`
          if var_type.kind.non_null? && !arg_type.kind.non_null?
            var_type = var_type.of_type
          end
          non_null_levels_match(arg_type.of_type, var_type.of_type)
        else
          true
        end
      end
    end
  end
end
